import 'package:flutter/foundation.dart';

class AppNavigationController extends ChangeNotifier {
  AppNavigationController._();

  static final AppNavigationController instance = AppNavigationController._();

  int? _requestedTab;

  int? takeRequestedTab() {
    final value = _requestedTab;
    _requestedTab = null;
    return value;
  }

  void openHome() => _request(0);
  void openMenu() => _request(1);
  void openOrders() => _request(2);
  void openMembership() => _request(3);

  void _request(int index) {
    _requestedTab = index;
    notifyListeners();
  }
}
