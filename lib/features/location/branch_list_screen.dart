import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'models/branch.dart';
import 'services/branch_service.dart';

class BranchListScreen extends StatelessWidget {
  final double userLatitude;
  final double userLongitude;
  final String serviceType;
  final Branch selectedBranch;

  const BranchListScreen({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
    required this.serviceType,
    required this.selectedBranch,
  });

  @override
  Widget build(BuildContext context) {
    final branches = BranchService().nearbyBranches(
      latitude: userLatitude,
      longitude: userLongitude,
      serviceType: serviceType,
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Choose Branch'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        itemCount: branches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = branches[index];
          final selected = item.branch.id == selectedBranch.id;

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.pop(context, item.branch),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.green : AppColors.beige,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: selected ? AppColors.beige : AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.branch.name,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${item.distanceKm.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            serviceType == 'delivery'
                                ? 'Delivery available'
                                : 'Pickup available',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.green,
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
