import 'package:flutter/material.dart';

import '../../../core/rewards/customer_play_store.dart';
import '../../../core/theme/app_colors.dart';

class PlayWinCard extends StatelessWidget {
  final VoidCallback onTap;

  const PlayWinCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CustomerPlayStore.instance,
      builder: (context, _) {
        final available = PlayGameType.values
            .where(CustomerPlayStore.instance.canPlay)
            .length;

        return Material(
          color: AppColors.greenDark,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      color: AppColors.beige,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PLAY & WIN',
                          style: TextStyle(
                            color: AppColors.beige,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Getin Play',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          available == 0
                              ? 'Today’s tries used · come back tomorrow'
                              : '$available daily ${available == 1 ? 'try' : 'tries'} ready',
                          style: const TextStyle(
                            color: Color(0xFFBCCBC5),
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.beige,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
