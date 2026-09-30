import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../data/customer_repository.dart';
import '../network/api_exception.dart';
import '../storage/secure_store.dart';
import 'customer_account_models.dart';
import 'customer_account_repository.dart';

class CustomerAuthStore extends ChangeNotifier {
  CustomerAuthStore._();

  static final CustomerAuthStore instance = CustomerAuthStore._();

  CustomerRepositoryContext? _context;
  CustomerAccountRepository? _repository;
  CustomerAccount? _customer;
  bool _busy = false;

  CustomerAccount? get customer => _customer;
  bool get isAuthenticated => _customer != null;
  bool get busy => _busy;
  bool get usesApi => _repository?.usesApi ?? false;

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
      notifyListeners();
      return result.customer;
    });
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
