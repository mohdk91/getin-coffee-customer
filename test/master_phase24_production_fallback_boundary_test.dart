import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';

void main() {
  test('Task 239 keeps demo repositories development-only', () {
    const development = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    );
    const production = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: '',
    );

    expect(development.allowsDemo, isTrue);
    expect(production.allowsDemo, isFalse);
  });

  test('Task 239 release fallback boundary remains narrowly scoped', () {
    final appConfig = File('lib/core/config/app_config.dart').readAsStringSync();
    final repository =
        File('lib/core/data/customer_repository.dart').readAsStringSync();
    final branches = File('lib/features/location/services/branch_service.dart')
        .readAsStringSync();
    final contentStore = File('lib/core/content/mobile_app_content_store.dart')
        .readAsStringSync();
    final hero = File('lib/features/home/widgets/hero_carousel.dart')
        .readAsStringSync();
    final splash = File('lib/features/splash/splash_screen.dart')
        .readAsStringSync();

    expect(appConfig, contains('&& !kReleaseMode'));
    expect(repository, contains('if (config.allowsDemo)'));
    expect(
      branches,
      contains(
        'return store.usesApi ? const <Branch>[] : _developmentFallback;',
      ),
    );
    expect(
      contentStore,
      contains('bool get usesApi => _repository?.context.usesApi ?? false;'),
    );
    expect(hero, contains('if (banners.isEmpty && store.usesApi)'));
    expect(hero, contains('return const SizedBox.shrink();'));
    expect(splash, contains('if (media == null && contentStore.usesApi)'));
    expect(
      splash,
      contains('if (!MobileAppContentStore.instance.usesApi)'),
    );
    expect(
      splash,
      contains(
        "VideoPlayerController.asset('assets/videos/getin_splash_compat.mp4')",
      ),
    );
  });
}
