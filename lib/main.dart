import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();

  // Paint the first Flutter frame immediately. API-backed store bootstrap now
  // happens inside the app so a slow/offline backend can never leave Android
  // displaying only its native launch window.
  runApp(GetinCoffeeApp(config: config));
}
