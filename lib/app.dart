import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'features/splash/splash_screen.dart';

class GetinCoffeeApp extends StatelessWidget {
  const GetinCoffeeApp({super.key});

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
      home: const SplashScreen(),
    );
  }
}
