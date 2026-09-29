import 'package:flutter/material.dart';

import '../../core/customer/customer_country.dart';
import '../../core/favorites/customer_favorites_store.dart';
import '../../core/gift_cards/customer_gift_card_store.dart';
import '../../core/rewards/customer_rewards_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/vouchers/customer_voucher_store.dart';
import '../../core/widgets/customer_avatar.dart';
import '../rewards/rewards_screen.dart' as rewards_ui;
import '../play/getin_play_screen.dart';
import 'profile_photo_actions.dart';
import 'profile_pages.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenMembership;

  const ProfileScreen({
    super.key,
    required this.onOpenOrders,
    required this.onOpenMembership,
  });

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        CustomerRewardsStore.instance,
        CustomerVoucherStore.instance,
        CustomerFavoritesStore.instance,
        CustomerGiftCardStore.instance,
      ]),
      builder: (context, _) {
        final rewards = CustomerRewardsStore.instance;
        final vouchers = CustomerVoucherStore.instance;
        final favorites = CustomerFavoritesStore.instance;
        final giftCards = CustomerGiftCardStore.instance;
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _ProfileHeader(
                    onSettings: () => _push(
                      context,
                      const SettingsScreen(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _MembershipBanner(
                          onTap: onOpenMembership,
                        ),
                        const SizedBox(height: 12),
                        _StatsRow(rewards: rewards),
                        const SizedBox(height: 18),
                        _ProfileSection(
                          title: 'Your Getin',
                          children: [
                            _ProfileTile(
                              icon: Icons.stars_rounded,
                              label: 'Rewards',
                              subtitle: rewards.starsUntilNextReward == 0
                                  ? '${rewards.stars} Stars · reward ready'
                                  : '${rewards.stars} Stars · ${rewards.starsUntilNextReward} until your next reward',
                              onTap: () => _push(
                                context,
                                const rewards_ui.RewardsScreen(),
                              ),
                            ),
                            _ProfileTile(
                              icon: Icons.sports_esports_rounded,
                              label: 'Play & Win',
                              subtitle:
                                  'Spin, stop the timer and win Getin rewards',
                              onTap: () => _push(
                                context,
                                const GetinPlayScreen(),
                              ),
                            ),
                            _ProfileTile(
                              icon: Icons.receipt_long_outlined,
                              label: 'Orders',
                              subtitle:
                                  'Track active orders and reorder favorites',
                              onTap: onOpenOrders,
                            ),
                            _ProfileTile(
                              icon: Icons.confirmation_number_outlined,
                              label: 'Vouchers',
                              subtitle: vouchers.appliedVouchers.isNotEmpty
                                  ? '${vouchers.availableCount} available · 1 applied'
                                  : '${vouchers.availableCount} available',
                              onTap: () => _push(
                                context,
                                const VouchersScreen(),
                              ),
                            ),
                            _ProfileTile(
                              icon: Icons.workspace_premium_outlined,
                              label: 'Membership',
                              subtitle: 'Member prices, 1.5× Stars and perks',
                              onTap: onOpenMembership,
                            ),
                            _ProfileTile(
                              icon: Icons.favorite_border_rounded,
                              label: 'Favorites',
                              subtitle: favorites.count == 0
                                  ? 'No saved products yet'
                                  : '${favorites.count} saved product${favorites.count == 1 ? '' : 's'}',
                              onTap: () => _push(
                                context,
                                const FavoritesScreen(),
                              ),
                              last: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ProfileSection(
                          title: 'Account',
                          children: [
                            _ProfileTile(
                              icon: Icons.person_outline_rounded,
                              label: 'Personal Information',
                              subtitle: 'Name, email, phone and birthday',
                              onTap: () => _push(
                                context,
                                const PersonalInformationScreen(),
                              ),
                            ),
                            _ProfileTile(
                              icon: Icons.location_on_outlined,
                              label: 'Saved Addresses',
                              subtitle: 'Home, work and delivery locations',
                              onTap: () => _push(
                                context,
                                const SavedAddressesScreen(),
                              ),
                            ),
                            _ProfileTile(
                              icon: Icons.credit_card_rounded,
                              label: 'Payment Methods',
                              subtitle: 'Manage cards and default payment',
                              onTap: () => _push(
                                context,
                                const PaymentMethodsScreen(),
                              ),
                              last: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ProfileSection(
                          title: 'Benefits',
                          children: [
                            _ProfileTile(
                              icon: Icons.group_add_outlined,
                              label: 'Refer a Friend',
                              subtitle: 'Share Getin and earn rewards',
                              onTap: () => _push(
                                context,
                                const ReferFriendScreen(),
                              ),
                            ),
                            _ProfileTile(
                              icon: Icons.card_giftcard_rounded,
                              label: 'Gift Cards',
                              subtitle:
                                  'EGP ${giftCards.balance.toStringAsFixed(giftCards.balance == giftCards.balance.roundToDouble() ? 0 : 2)} balance · send or redeem',
                              onTap: () => _push(
                                context,
                                const GiftCardsScreen(),
                              ),
                            ),
                            _ProfileTile(
                              icon: Icons.cake_outlined,
                              label: 'Birthday Reward',
                              subtitle: 'Your birthday perk and eligibility',
                              onTap: () => _push(
                                context,
                                const BirthdayRewardScreen(),
                              ),
                              last: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ProfileSection(
                          title: 'Support',
                          children: [
                            _ProfileTile(
                              icon: Icons.support_agent_rounded,
                              label: 'Help & Support',
                              subtitle:
                                  'Orders, payments, delivery and account',
                              onTap: () => _push(
                                context,
                                const HelpSupportScreen(),
                              ),
                            ),
                            _ProfileTile(
                              icon: Icons.info_outline_rounded,
                              label: 'About Getin',
                              subtitle: 'Our story, policies and app version',
                              onTap: () => _push(
                                context,
                                const AboutGetinScreen(),
                              ),
                            ),
                            _ProfileTile(
                              icon: Icons.settings_outlined,
                              label: 'Settings',
                              subtitle: 'Notifications, language and privacy',
                              onTap: () => _push(
                                context,
                                const SettingsScreen(),
                              ),
                            ),
                            _ProfileTile(
                              icon: Icons.logout_rounded,
                              label: 'Log Out',
                              danger: true,
                              onTap: () => showLogoutSheet(context),
                              last: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onSettings;

  const _ProfileHeader({
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: const BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          CustomerAvatar(
            size: 58,
            onTap: () => showProfilePhotoActions(context),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mohammed Abukalloub',
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: AppColors.beige,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<CustomerCountry>(
                  valueListenable: CustomerCountryStore.current,
                  builder: (context, country, child) {
                    return Row(
                      children: [
                        Text(
                          country.flagEmoji,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            country.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.09),
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: onSettings,
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.beige,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _MembershipBanner({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.greenDark,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).width < 380 ? 168 : 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/profile/profile_membership_banner.jpg',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.38),
                colorBlendMode: BlendMode.darken,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'GETIN MEMBERSHIP',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'More coffee.\nMore good days.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Member prices · 1.5× Stars · monthly perks',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.beige,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _StatsRow extends StatelessWidget {
  final CustomerRewardsStore rewards;

  const _StatsRow({required this.rewards});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('${rewards.stars}', 'Stars', Icons.star_rounded),
      ('2', 'Vouchers', Icons.confirmation_number_outlined),
      ('${rewards.activeRewardCount}', 'Rewards', Icons.local_cafe_outlined),
      ('EGP 280', 'Saved', Icons.savings_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        const gap = 7.0;
        final cardWidth = compact
            ? (constraints.maxWidth - gap) / 2
            : (constraints.maxWidth - (gap * 3)) / 4;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(
            stats.length,
            (index) => SizedBox(
              width: cardWidth,
              child: Container(
                constraints: const BoxConstraints(minHeight: 82),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      stats[index].$3,
                      color: index == 0 ? AppColors.gold : AppColors.green,
                      size: 18,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      stats[index].$1,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats[index].$2,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: 8,
          ),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;
  final bool last;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.danger = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB94A48) : AppColors.green;

    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 3,
          ),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: danger ? const Color(0xFFFCEDEC) : AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 8.5,
                    ),
                  ),
                ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: danger ? const Color(0xFFB94A48) : AppColors.muted,
          ),
          onTap: onTap,
        ),
        if (!last)
          const Divider(
            height: 1,
            indent: 62,
            color: AppColors.border,
          ),
      ],
    );
  }
}
