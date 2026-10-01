import 'package:flutter/foundation.dart';

import '../data/customer_repository.dart';
import 'mobile_app_content_models.dart';
import 'mobile_app_content_repository.dart';

class MobileAppContentStore extends ChangeNotifier {
  MobileAppContentStore._();

  static final MobileAppContentStore instance = MobileAppContentStore._();
  MobileAppContentRepository? _repository;
  MobileAppContentSnapshot _snapshot = const MobileAppContentSnapshot();
  Object? _lastError;
  bool _loading = false;

  MobileAppContentSnapshot get snapshot => _snapshot;
  MobileContentItem? get splash => _snapshot.splash;
  List<MobileContentItem> get onboarding => _snapshot.onboarding;
  List<MobileBannerContent> get heroBanners => _snapshot.heroBanners;
  List<MobileBannerContent> get secondaryBanners => _snapshot.secondaryBanners;
  List<MobileHomeSectionConfig> get homeSections => _snapshot.homeSections;
  MobileMarketContext? get marketContext => _snapshot.marketContext;
  List<MobileMenuCollection> get menuCollections => _snapshot.menuCollections;
  bool get loading => _loading;
  Object? get lastError => _lastError;

  static Future<void> initialize(CustomerRepositoryContext context) async {
    instance._repository = MobileAppContentRepository(context);
    if (!context.usesApi) return;
    await instance.refresh();
  }

  Future<void> refresh({
    int? branchId,
    String language = 'en',
    String? market,
    String? fulfillment,
  }) async {
    final repository = _repository;
    if (repository == null) return;
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      _snapshot = await repository.load(
        branchId: branchId,
        language: language,
        market: market,
        fulfillment: fulfillment,
      );
    } catch (error) {
      _lastError = error;
      // Keep the last valid snapshot and allow local UI fallbacks.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  MobileHomeSectionConfig? section(String key) {
    for (final section in _snapshot.homeSections) {
      if (section.key == key) return section;
    }
    return null;
  }
}
