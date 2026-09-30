import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/system/mobile_system_config.dart';

void main() {
  test('customer parses Laravel public mobile configuration', () {
    final config = MobileSystemConfig.fromApiEnvelope(<String, dynamic>{
      'data': <String, dynamic>{
        'api_version': 'v1',
        'mobile_apps': <String, dynamic>{
          'ios': <String, dynamic>{
            'minimum_version': '2.0.0',
            'latest_version': '2.5.0',
          },
          'android': <String, dynamic>{
            'minimum_version': '3.0.0',
            'latest_version': '3.4.0',
          },
          'force_update_enabled': true,
          'maintenance': <String, dynamic>{
            'enabled': false,
            'message': null,
          },
        },
        'client': <String, dynamic>{
          'platform': 'android',
          'version': '3.0.0',
          'version_valid': true,
          'update_available': true,
          'update_required': true,
        },
        'languages': <String, dynamic>{
          'default': 'en',
          'supported': <String>['en', 'ar'],
        },
      },
    });

    expect(config.android.latestVersion, '3.4.0');
    expect(config.client.updateRequired, isTrue);
    expect(config.supportedLanguages, <String>['en', 'ar']);
  });
}
