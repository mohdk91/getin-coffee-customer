import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/system/mobile_system_config_repository.dart';
import 'core/theme/app_colors.dart';
import 'core/widgets/mobile_startup_gate.dart';
import 'features/splash/splash_screen.dart';

class GetinCoffeeApp extends StatelessWidget {
  final AppConfig config;

  const GetinCoffeeApp({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Getin Coffee',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          primary: AppColors.green,
          surface: AppColors.cream,
        ),
      ),
      home: MobileStartupGate(
        appConfig: config,
        loader: config.isApiConfigured
            ? MobileSystemConfigRepository(ApiClient(config))
            : null,
        child: const SplashScreen(),
      ),
    );
  }
}
