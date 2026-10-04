import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../catalog/customer_catalog_store.dart';
import '../content/mobile_app_content_store.dart';
import '../navigation/app_navigation_controller.dart';
import '../../features/location/models/branch.dart';
import '../../features/home/live_offers_bundles_screen.dart';
import '../../features/play/getin_play_screen.dart';
import '../../features/product/product_detail_screen.dart';
import '../../features/rewards/rewards_screen.dart';
import 'mobile_app_content_models.dart';

class MobileContentNavigation {
  const MobileContentNavigation._();

  static Future<void> open(
    BuildContext context,
    MobileContentDestination destination, {
    required Branch branch,
    required String serviceType,
    VoidCallback? fallback,
  }) async {
    switch (destination.type) {
      case 'home':
        AppNavigationController.instance.openHome();
        return;
      case 'collection':
        final collectionId = int.tryParse(destination.value ?? '');
        if (collectionId != null) {
          final matches = MobileAppContentStore.instance.menuCollections.where(
            (collection) => collection.id == collectionId,
          );
          if (matches.isNotEmpty) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LiveOfferCollectionDetailScreen(
                  branchId: branch.id,
                  branchName: branch.name,
                  serviceType: serviceType,
                  collection: matches.first,
                ),
              ),
            );
            return;
          }
        }
        AppNavigationController.instance.openMenu();
        return;
      case 'category':
      case 'promotion':
        AppNavigationController.instance.openMenu();
        return;
      case 'rewards':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RewardsScreen()),
        );
        return;
      case 'getin_play':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GetinPlayScreen()),
        );
        return;
      case 'product':
        final productId = int.tryParse(destination.value ?? '');
        if (productId == null) break;
        final product = await CustomerCatalogStore.instance.loadProduct(
          branch.id,
          productId,
        );
        if (product == null || !context.mounted) break;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              name: product.name,
              description: product.shortDescription,
              image: product.imageUrl ?? '',
              price: product.displayPrice,
              branchName: branch.name,
              serviceType: serviceType,
              branchId: branch.id,
              catalogProduct: product,
            ),
          ),
        );
        return;
      case 'external_url':
        final uri = Uri.tryParse(destination.value ?? '');
        if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
        break;
      case 'none':
      default:
        break;
    }
    fallback?.call();
  }
}
