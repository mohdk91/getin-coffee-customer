import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/bootstrap/customer_app_bootstrap.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();

  // Paint Flutter immediately so Android never stays on a black native launch
  // window while API-backed repositories initialize.
  runApp(GetinCoffeeApp(config: config));

  // Bootstrap runs underneath the real video splash. Splash waits for this
  // future only when it is ready to navigate to onboarding/authentication.
  unawaited(CustomerAppBootstrap.instance.start(config));
}
