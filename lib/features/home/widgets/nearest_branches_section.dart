import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../location/models/branch.dart';
import '../../location/services/branch_service.dart';
import '../../location/widgets/branch_image.dart';

class NearestBranchesSection extends StatelessWidget {
  final List<BranchDistance> branches;
  final Branch selectedBranch;
  final ValueChanged<Branch> onBranchSelected;
  final VoidCallback onViewAll;

  const NearestBranchesSection({
    super.key,
    required this.branches,
    required this.selectedBranch,
    required this.onBranchSelected,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final visible = branches.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Nearest Branches',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onViewAll,
              iconAlignment: IconAlignment.end,
              icon: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
              ),
              label: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 9.0;
            final cardWidth = (constraints.maxWidth - gap * 2) / 3;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                visible.length,
                (index) {
                  final item = visible[index];
                  final selected = item.branch.id == selectedBranch.id;

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == visible.length - 1 ? 0 : gap,
                    ),
                    child: SizedBox(
                      width: cardWidth,
                      child: _BranchCard(
                        item: item,
                        selected: selected,
                        onTap: () => onBranchSelected(item.branch),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: AppColors.beige.withOpacity(0.42),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.green,
                size: 17,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Can’t find your favorite item? Switch to another nearby branch to check availability.',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BranchCard extends StatelessWidget {
  final BranchDistance item;
  final bool selected;
  final VoidCallback onTap;

  const _BranchCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.45,
                child: BranchImage(
                  branch: item.branch,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  8,
                  8,
                  7,
                  9,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 17,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _branchDisplayName(item.branch.name),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.chevron_right_rounded,
                          color: AppColors.green,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _branchDisplayName(String name) {
  return name
      .replaceFirst(RegExp(r'^getin\s+', caseSensitive: false), '')
      .trim();
}
