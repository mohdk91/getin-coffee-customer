import 'dart:io';

import '../data/customer_repository.dart';
import '../network/api_exception.dart';
import '../storage/secure_store.dart';
import '../system/app_runtime_info.dart';

class CustomerDeviceInfo {
  final int id;
  final String deviceId;
  final String platform;
  final String? deviceName;
  final String? appVersion;
  final String? osVersion;
  final bool pushNotificationsRegistered;
  final DateTime? lastSeenAt;

  const CustomerDeviceInfo({
    required this.id,
    required this.deviceId,
    required this.platform,
    this.deviceName,
    this.appVersion,
    this.osVersion,
    required this.pushNotificationsRegistered,
    this.lastSeenAt,
  });

  factory CustomerDeviceInfo.fromJson(Map<String, dynamic> json) {
    return CustomerDeviceInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      deviceId: json['device_id']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'unknown',
      deviceName: json['device_name']?.toString(),
      appVersion: json['app_version']?.toString(),
      osVersion: json['os_version']?.toString(),
      pushNotificationsRegistered:
          json['push_notifications_registered'] == true,
      lastSeenAt: DateTime.tryParse(json['last_seen_at']?.toString() ?? ''),
    );
  }
}

class CustomerSessionInfo {
  final int id;
  final String name;
  final bool isCurrent;
  final DateTime? lastActiveAt;
  final DateTime? expiresAt;
  final CustomerDeviceInfo? device;

  const CustomerSessionInfo({
    required this.id,
    required this.name,
    required this.isCurrent,
    this.lastActiveAt,
    this.expiresAt,
    this.device,
  });

  factory CustomerSessionInfo.fromJson(Map<String, dynamic> json) {
    final rawDevice = json['device'];
    return CustomerSessionInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Customer session',
      isCurrent: json['is_current'] == true,
      lastActiveAt: DateTime.tryParse(json['last_active_at']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      device: rawDevice is Map
          ? CustomerDeviceInfo.fromJson(Map<String, dynamic>.from(rawDevice))
          : null,
    );
  }
}

class CustomerSessionRepository {
  final CustomerRepositoryContext context;

  const CustomerSessionRepository(this.context);

  bool get usesApi => context.usesApi;

  Future<void> registerCurrentDevice({
    AppRuntimeInfoProvider runtimeInfoProvider =
        const PackageAppRuntimeInfoProvider(),
  }) async {
    if (!usesApi) return;
    final runtime = await runtimeInfoProvider.load();
    if (runtime.platform != 'ios' && runtime.platform != 'android') return;
    var deviceId = await context.secureStore.read(SecureStoreKeys.deviceId);
    if (deviceId == null || deviceId.trim().length < 8) {
      deviceId =
          'getin-${runtime.platform}-${DateTime.now().microsecondsSinceEpoch}';
      await context.secureStore.write(SecureStoreKeys.deviceId, deviceId);
    }
    await context.apiClient.requestJson(
      'PUT',
      '/v1/customer/device',
      authenticated: true,
      body: <String, dynamic>{
        'device_id': deviceId,
        'platform': runtime.platform,
        'device_name': Platform.localHostname,
        'app_version': '${runtime.version}+${runtime.buildNumber}',
        'os_version': Platform.operatingSystemVersion,
      },
    );
  }

  Future<List<CustomerSessionInfo>> listSessions() async {
    if (!usesApi) {
      return const <CustomerSessionInfo>[
        CustomerSessionInfo(id: 1, name: 'Demo session', isCurrent: true),
      ];
    }
    final payload = await context.apiClient.getJson(
      '/v1/customer/sessions',
      authenticated: true,
    );
    final data = payload['data'];
    if (data is! List) {
      throw const ApiException(
          'We couldn’t load your active sessions. Please try again.');
    }
    return data
        .whereType<Map>()
        .map((item) => CustomerSessionInfo.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<void> revokeSession(int id) async {
    if (!usesApi) return;
    await context.apiClient.requestJson(
      'DELETE',
      '/v1/customer/sessions/$id',
      authenticated: true,
    );
  }

  Future<void> revokeCurrent() async {
    if (!usesApi) return;
    await context.apiClient.requestJson(
      'DELETE',
      '/v1/customer/sessions/current',
      authenticated: true,
    );
  }

  Future<void> revokeAll() async {
    if (!usesApi) return;
    await context.apiClient.requestJson(
      'DELETE',
      '/v1/customer/sessions',
      authenticated: true,
    );
  }
}
