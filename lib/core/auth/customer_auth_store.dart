import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../data/customer_repository.dart';
import '../network/api_exception.dart';
import '../storage/secure_store.dart';
import 'customer_account_models.dart';
import 'customer_account_repository.dart';
import 'customer_session_repository.dart';

class CustomerAuthStore extends ChangeNotifier {
  CustomerAuthStore._();

  static final CustomerAuthStore instance = CustomerAuthStore._();

  CustomerRepositoryContext? _context;
  CustomerAccountRepository? _repository;
  CustomerAccount? _customer;
  CustomerSessionRepository? _sessionRepository;
  List<CustomerSessionInfo> _sessions = const <CustomerSessionInfo>[];
  bool _busy = false;

  CustomerAccount? get customer => _customer;
  bool get isAuthenticated => _customer != null;
  bool get busy => _busy;
  bool get usesApi => _repository?.usesApi ?? false;
  List<CustomerSessionInfo> get sessions => List.unmodifiable(_sessions);

  CustomerAccountRepository get repository {
    final repository = _repository;
    if (repository == null) {
      throw StateError('CustomerAuthStore has not been initialized.');
    }
    return repository;
  }

  CustomerRepositoryContext get context {
    final value = _context;
    if (value == null) {
      throw StateError('CustomerAuthStore has not been initialized.');
    }
    return value;
  }

  static Future<void> initialize(
    AppConfig config, {
    SecureStore? secureStore,
  }) async {
    final context = CustomerRepositoryContext(
      config: config,
      secureStore: secureStore,
    );
    instance._context = context;
    instance._repository = CustomerAccountRepository(context);
    instance._sessionRepository = CustomerSessionRepository(context);
    instance._customer = null;
    instance._sessions = const <CustomerSessionInfo>[];
    instance._busy = false;
    await instance._restoreSession();
  }

  Future<CustomerAccount> login({
    required String identifier,
    required String password,
  }) async {
    return _runBusy(() async {
      final result = await repository.login(
        identifier: identifier,
        password: password,
      );
      await context.secureStore.write(
        SecureStoreKeys.accessToken,
        result.token,
      );
      _customer = result.customer;
      await _persistCustomer();
      notifyListeners();
      await _registerDeviceBestEffort();
      return result.customer;
    });
  }


  Future<CustomerAccount> socialLogin({
    required String provider,
    required String identityToken,
    String? nonce,
    String? displayName,
  }) async {
    return _runBusy(() async {
      final result = await repository.socialLogin(
        provider: provider,
        identityToken: identityToken,
        nonce: nonce,
        displayName: displayName,
      );
      await context.secureStore.write(
        SecureStoreKeys.accessToken,
        result.token,
      );
      _customer = result.customer;
      await _persistCustomer();
      notifyListeners();
      await _registerDeviceBestEffort();
      return result.customer;
    });
  }


  Future<CustomerAccount> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String language = 'en',
    String? referralCode,
  }) async {
    return _runBusy(() async {
      final result = await repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        language: language,
        referralCode: referralCode,
      );
      await context.secureStore.write(
        SecureStoreKeys.accessToken,
        result.token,
      );
      _customer = result.customer;
      await _persistCustomer();
      notifyListeners();
      await _registerDeviceBestEffort();
      return result.customer;
    });
  }


  Future<CustomerAccount> refreshProfile() async {
    return _runBusy(() async {
      final account = await repository.fetchProfile();
      _customer = account;
      await _persistCustomer();
      notifyListeners();
      return account;
    });
  }

  Future<CustomerAccount> updateProfile(Map<String, dynamic> changes) async {
    return _runBusy(() async {
      final account = await repository.updateProfile(changes);
      _customer = account;
      await _persistCustomer();
      notifyListeners();
      return account;
    });
  }

  Future<Map<String, dynamic>> sendOtp({bool resend = false}) async {
    return _runBusy(() => repository.sendOtp(resend: resend));
  }

  Future<CustomerAccount> verifyOtp(String code) async {
    return _runBusy(() async {
      final account = await repository.verifyOtp(code);
      _customer = account;
      await _persistCustomer();
      notifyListeners();
      return account;
    });
  }

  Future<void> _restoreSession() async {
    final token = await context.secureStore.read(SecureStoreKeys.accessToken);
    if (token == null || token.trim().isEmpty) return;

    final cached = await context.secureStore.read(
      SecureStoreKeys.customerAccountCache,
    );
    if (cached != null && cached.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(cached);
        if (decoded is Map) {
          _customer = CustomerAccount.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {
        await context.secureStore.delete(
          SecureStoreKeys.customerAccountCache,
        );
      }
    }

    if (!usesApi) {
      notifyListeners();
      return;
    }

    try {
      final account = await repository.fetchProfile();
      _customer = account;
      await _persistCustomer();
      await _registerDeviceBestEffort();
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await context.secureStore.delete(SecureStoreKeys.accessToken);
        await _clearCustomerCache();
        _customer = null;
      }
      // Offline/transient API failures retain the cached account for startup.
    }
    notifyListeners();
  }

  Future<void> _persistCustomer() async {
    final customer = _customer;
    if (customer == null) return;
    await context.secureStore.write(
      SecureStoreKeys.customerAccountCache,
      jsonEncode(customer.toJson()),
    );
  }

  Future<void> _clearCustomerCache() async {
    await context.secureStore.delete(
      SecureStoreKeys.customerAccountCache,
    );
  }

  Future<void> _registerDeviceBestEffort() async {
    try {
      await _sessionRepository?.registerCurrentDevice();
    } catch (_) {
      // Device registration must never invalidate a successful login.
    }
  }

  Future<List<CustomerSessionInfo>> refreshSessions() async {
    final repository = _sessionRepository;
    if (repository == null) return const <CustomerSessionInfo>[];
    final sessions = await repository.listSessions();
    _sessions = sessions;
    notifyListeners();
    return sessions;
  }

  Future<void> revokeSession(int id) async {
    final repository = _sessionRepository;
    if (repository == null) return;
    await repository.revokeSession(id);
    _sessions = _sessions.where((session) => session.id != id).toList();
    notifyListeners();
  }

  Future<void> logoutCurrent() async {
    final repository = _sessionRepository;
    if (repository != null && repository.usesApi) {
      try {
        await repository.revokeCurrent();
      } catch (_) {
        // Local sign-out must still remove the bearer token if the network is down.
      }
    }
    await context.secureStore.delete(SecureStoreKeys.accessToken);
    await _clearCustomerCache();
    _customer = null;
    _sessions = const <CustomerSessionInfo>[];
    notifyListeners();
  }

  Future<void> logoutAll() async {
    final repository = _sessionRepository;
    if (repository != null && repository.usesApi) {
      await repository.revokeAll();
    }
    await context.secureStore.delete(SecureStoreKeys.accessToken);
    await _clearCustomerCache();
    _customer = null;
    _sessions = const <CustomerSessionInfo>[];
    notifyListeners();
  }

  Future<T> _runBusy<T>(Future<T> Function() action) async {
    if (_busy) {
      throw const ApiException('Please wait for the current request to finish.');
    }
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  String userMessage(Object error) {
    if (error is ApiException) {
      for (final value in error.errors.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String && value.trim().isNotEmpty) return value;
      }
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }
}
