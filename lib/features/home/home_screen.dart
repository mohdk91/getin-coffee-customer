import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/content/mobile_content_navigation.dart';
import '../../core/membership/customer_membership_store.dart';
import '../../core/navigation/app_navigation_controller.dart';
import '../../core/rewards/customer_rewards_store.dart';
import '../../core/rewards/customer_stamp_card_store.dart';
import '../../core/theme/app_colors.dart';
import '../location/branch_list_screen.dart';
import '../location/branch_map_screen.dart';
import '../location/models/branch.dart';
import '../location/services/branch_service.dart';
import '../notifications/notifications_screen.dart';
import '../play/getin_play_screen.dart';
import '../qr/qr_scanner_screen.dart';
import '../search/home_search_screen.dart';
import '../rewards/rewards_screen.dart';
import 'widgets/hero_carousel.dart';
import 'widgets/home_header.dart';
import 'widgets/menu_categories_section.dart';
import 'widgets/managed_product_sections.dart';
import 'widgets/nearest_branches_section.dart';
import 'widgets/play_win_card.dart';
import 'widgets/qr_map_row.dart';
import 'widgets/secondary_banner_card.dart';
import 'widgets/rewards_progress_card.dart';

class HomeScreen extends StatelessWidget {
  final Branch branch;
  final String serviceType;
  final double userLatitude;
  final double userLongitude;
  final ValueChanged<Branch> onBranchChanged;
  final ValueChanged<String> onServiceChanged;

  const HomeScreen({
    super.key,
    required this.branch,
    required this.serviceType,
    required this.userLatitude,
    required this.userLongitude,
    required this.onBranchChanged,
    required this.onServiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    void openMenu() {
      AppNavigationController.instance.openMenu();
    }

    void openContentDestination(destination) {
      unawaited(
        MobileContentNavigation.open(
          context,
          destination,
          branch: branch,
          serviceType: serviceType,
          fallback: openMenu,
        ),
      );
    }

    final branchService = BranchService();

    final nearbyBranches = branchService.nearbyBranches(
      latitude: userLatitude,
      longitude: userLongitude,
      serviceType: serviceType,
    );

    final selectedDistance = branchService.distanceKm(
      latitude: userLatitude,
      longitude: userLongitude,
      branch: branch,
    );

    Future<void> chooseBranch() async {
      final selected = await Navigator.push<Branch>(
        context,
        MaterialPageRoute(
          builder: (_) => BranchListScreen(
            userLatitude: userLatitude,
            userLongitude: userLongitude,
            serviceType: serviceType,
            selectedBranch: branch,
          ),
        ),
      );

      if (selected != null) {
        onBranchChanged(selected);
      }
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        CustomerRewardsStore.instance,
        CustomerStampCardStore.instance,
        CustomerMembershipStore.instance,
      ]),
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: HomeHeader(
                  branch: branch,
                  distanceKm: selectedDistance,
                  serviceType: serviceType,
                  stars: CustomerRewardsStore.instance.stars,
                  onNotification: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  onRewards: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RewardsScreen(),
                      ),
                    );
                  },
                  onSearch: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HomeSearchScreen(
                          branch: branch,
                          serviceType: serviceType,
                        ),
                      ),
                    );
                  },
                  onFilter: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HomeSearchScreen(
                          branch: branch,
                          serviceType: serviceType,
                          openFilters: true,
                        ),
                      ),
                    );
                  },
                  onServiceChanged: onServiceChanged,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  15,
                  16,
                  28,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      NearestBranchesSection(
                        branches: nearbyBranches,
                        selectedBranch: branch,
                        onBranchSelected: onBranchChanged,
                        onViewAll: chooseBranch,
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      RewardsProgressCard(
                        stars: CustomerRewardsStore.instance.stars,
                        targetStars:
                            CustomerRewardsStore.instance.nextRewardTarget,
                        currentStamps:
                            CustomerStampCardStore.instance.currentStamps,
                        memberActive: CustomerMembershipStore.instance.isActive,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RewardsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      PlayWinCard(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const GetinPlayScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      QrMapRow(
                        branch: branch,
                        distanceKm: selectedDistance,
                        onScanQr: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QrScannerScreen(),
                            ),
                          );
                        },
                        onOpenMap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BranchMapScreen(
                                branch: branch,
                                userLatitude: userLatitude,
                                userLongitude: userLongitude,
                              ),
                            ),
                          );
                        },
                        onChangeBranch: chooseBranch,
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      InkWell(
                        onTap: openMenu,
                        borderRadius: BorderRadius.circular(18),
                        child: HeroCarousel(
                          branchId: branch.id,
                          marketCode: branch.countryCode,
                          fulfillment: serviceType,
                          onOrderNow: openMenu,
                          onDestination: openContentDestination,
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      SecondaryBannerCard(
                          onDestination: openContentDestination),
                      const SizedBox(
                        height: 18,
                      ),
                      InkWell(
                        onTap: openMenu,
                        borderRadius: BorderRadius.circular(18),
                        child: MenuCategoriesSection(
                          branchId: branch.id,
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      ManagedProductSections(
                        branchId: branch.id,
                        branchName: branch.name,
                        serviceType: serviceType,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
