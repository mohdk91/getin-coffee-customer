import 'package:flutter/material.dart';

import '../../core/membership/customer_membership_store.dart';
import '../../core/theme/app_colors.dart';

enum MembershipBillingCycle {
  monthly,
  annual,
}

class MembershipScreen extends StatefulWidget {
  final bool showBackButton;

  const MembershipScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  MembershipBillingCycle _billingCycle = MembershipBillingCycle.monthly;

  String get _heroPrice {
    return _billingCycle == MembershipBillingCycle.monthly
        ? 'EGP 129 / month'
        : 'EGP 1,239 / year';
  }

  String get _ctaLabel {
    return _billingCycle == MembershipBillingCycle.monthly
        ? 'Join Getin Membership · EGP 129/month'
        : 'Join Getin Membership · EGP 1,239/year';
  }

  @override
  Widget build(BuildContext context) {
    if (CustomerMembershipStore.instance.usesApi) {
      return _LiveMembershipScreen(showBackButton: widget.showBackButton);
    }
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _MembershipHeader(
                      price: _heroPrice,
                      showBackButton: widget.showBackButton,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        0,
                      ),
                      child: _BillingSelector(
                        selected: _billingCycle,
                        onChanged: (value) {
                          setState(() {
                            _billingCycle = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        22,
                        16,
                        0,
                      ),
                      child: _BenefitSection(),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        22,
                        16,
                        0,
                      ),
                      child: _MonthlyPerksSection(),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        22,
                        16,
                        0,
                      ),
                      child: _MemberPricesSection(),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        18,
                        16,
                        22,
                      ),
                      child: _WhyJoinCard(),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: CustomerMembershipStore.instance,
              builder: (context, _) => _StickyMembershipAction(
                label: CustomerMembershipStore.instance.isActive
                    ? 'Membership Active · 1.5× Stars'
                    : _ctaLabel,
                billingCycle: _billingCycle.name,
                active: CustomerMembershipStore.instance.isActive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _LiveMembershipScreen extends StatelessWidget {
  final bool showBackButton;

  const _LiveMembershipScreen({required this.showBackButton});

  @override
  Widget build(BuildContext context) {
    final store = CustomerMembershipStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final current = store.currentTier;
        final next = store.nextTier;
        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            automaticallyImplyLeading: showBackButton,
            backgroundColor: AppColors.cream,
            surfaceTintColor: AppColors.cream,
            foregroundColor: AppColors.green,
            elevation: 0,
            title: const Text(
              'GETIN Membership',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: store.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR TIER',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        current?.name ?? 'GETIN',
                        style: const TextStyle(
                          color: AppColors.beige,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${store.earningMultiplierLabel} Stars earning · ${store.lifetimePoints} lifetime Stars',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: store.progress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        next == null
                            ? 'Highest tier reached'
                            : '${store.pointsToNext} Stars to ${next.name}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'TIERS',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                ...store.tiers.map(
                  (tier) => _LiveTierCard(
                    tier: tier,
                    current: current?.id == tier.id,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tier status, Stars multipliers and benefits are managed by GETIN and update automatically from your account.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                    height: 1.4,
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

class _LiveTierCard extends StatelessWidget {
  final CustomerMembershipTier tier;
  final bool current;

  const _LiveTierCard({required this.tier, required this.current});

  @override
  Widget build(BuildContext context) {
    final benefits = tier.benefits.entries
        .where((entry) => entry.value == true || entry.value.toString().isNotEmpty)
        .map((entry) => entry.key.replaceAll('_', ' '))
        .toList(growable: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: current ? AppColors.green : AppColors.border,
          width: current ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.name,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${tier.minimumLifetimePoints} lifetime Stars · ${tier.multiplierLabel} earning',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
                if (benefits.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    benefits.join(' · '),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (current)
            const Chip(
              label: Text('CURRENT'),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _MembershipHeader extends StatelessWidget {
  final String price;
  final bool showBackButton;

  const _MembershipHeader({
    required this.price,
    required this.showBackButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.green,
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (showBackButton) ...[
                Material(
                  color: Colors.white.withOpacity(0.08),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Back to checkout',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.beige,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Expanded(
                child: Text(
                  'Membership',
                  softWrap: false,
                  style: TextStyle(
                    color: AppColors.beige,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const Text(
                'Good Coffee\nBrighter Days',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 9,
                  height: 1.05,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: MediaQuery.sizeOf(context).width < 380 ? 232 : 218,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0D211C),
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  right: -34,
                  top: 0,
                  bottom: 0,
                  width: 250,
                  child: Image.asset(
                    'assets/images/membership/membership_hero_products.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF0D211C),
                        Color(0xF20D211C),
                        Color(0x70132D26),
                        Color(0x00132D26),
                      ],
                      stops: [
                        0.0,
                        0.48,
                        0.76,
                        1.0,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    18,
                    16,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GETIN COFFEE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Getin Membership',
                        style: TextStyle(
                          color: AppColors.beige,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'More coffee. More good days.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        price,
                        style: const TextStyle(
                          color: AppColors.beige,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.beige,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: AppColors.green,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Best Value',
                              style: TextStyle(
                                color: AppColors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingSelector extends StatelessWidget {
  final MembershipBillingCycle selected;
  final ValueChanged<MembershipBillingCycle> onChanged;

  const _BillingSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).width < 380 ? 82 : 74,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BillingOption(
              title: 'Monthly',
              subtitle: 'EGP 129 / month',
              selected: selected == MembershipBillingCycle.monthly,
              onTap: () {
                onChanged(
                  MembershipBillingCycle.monthly,
                );
              },
            ),
          ),
          Expanded(
            child: _BillingOption(
              title: 'Annual',
              subtitle: 'EGP 1,239 / year',
              note: 'Save 20%',
              selected: selected == MembershipBillingCycle.annual,
              onTap: () {
                onChanged(
                  MembershipBillingCycle.annual,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? note;
  final bool selected;
  final VoidCallback onTap;

  const _BillingOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.green : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: selected ? AppColors.beige : AppColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.beige
                            : AppColors.gold.withOpacity(0.24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        note!,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: selected ? Colors.white70 : AppColors.muted,
                  fontSize: 9.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitSection extends StatelessWidget {
  const _BenefitSection();

  static const benefits = <_MembershipBenefit>[
    _MembershipBenefit(
      icon: Icons.sell_outlined,
      title: 'Member Prices',
      subtitle: 'Exclusive pricing on selected drinks and food.',
    ),
    _MembershipBenefit(
      icon: Icons.star_rounded,
      title: '1.5× Stars',
      subtitle: 'Members earn 50% more Stars on every eligible order.',
    ),
    _MembershipBenefit(
      icon: Icons.local_shipping_outlined,
      title: 'Free Delivery',
      subtitle: 'Free delivery on qualifying orders.',
    ),
    _MembershipBenefit(
      icon: Icons.local_cafe_outlined,
      title: 'Monthly Free Drink',
      subtitle: 'One drink reward each month.',
    ),
    _MembershipBenefit(
      icon: Icons.card_giftcard_rounded,
      title: 'Birthday Reward',
      subtitle: 'A special birthday drink or treat.',
    ),
    _MembershipBenefit(
      icon: Icons.diamond_outlined,
      title: 'Early Access',
      subtitle: 'Priority access to seasonal drops and limited offers.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Save more on every cup',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Made for frequent Getin customers.',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 9.0;
            final columns = constraints.maxWidth < 400 ? 2 : 3;
            final itemWidth =
                (constraints.maxWidth - (gap * (columns - 1))) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: 9,
              children: benefits
                  .map(
                    (benefit) => SizedBox(
                      width: itemWidth,
                      child: _BenefitCard(
                        benefit: benefit,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final _MembershipBenefit benefit;

  const _BenefitCard({
    required this.benefit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(
              benefit.icon,
              color: AppColors.beige,
              size: 18,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            benefit.title,
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 10.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            benefit.subtitle,
            softWrap: true,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8.2,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyPerksSection extends StatelessWidget {
  const _MonthlyPerksSection();

  static const perks = <_MonthlyPerk>[
    _MonthlyPerk(
      title: '1 Free Drink',
      subtitle: 'Every month',
      image: 'assets/images/membership/perk_free_drink.jpg',
      dark: true,
    ),
    _MonthlyPerk(
      title: '2 Size Upgrades',
      subtitle: 'On any drink',
      image: 'assets/images/membership/perk_size_upgrade.jpg',
      dark: false,
    ),
    _MonthlyPerk(
      title: 'Coffee + Croissant',
      subtitle: 'Member bundle',
      image: 'assets/images/membership/perk_bundle.jpg',
      dark: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionTitle(
          title: 'Your Monthly Perks',
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 142,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: perks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 212,
                child: _PerkCard(
                  perk: perks[index],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PerkCard extends StatelessWidget {
  final _MonthlyPerk perk;

  const _PerkCard({
    required this.perk,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            perk.image,
            fit: BoxFit.cover,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: perk.dark
                    ? const [
                        Color(0xF20D211C),
                        Color(0xA80D211C),
                        Color(0x170D211C),
                      ]
                    : const [
                        Color(0xE8F7F5F0),
                        Color(0xBDF7F5F0),
                        Color(0x10F7F5F0),
                      ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    perk.title,
                    style: TextStyle(
                      color: perk.dark ? Colors.white : AppColors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    perk.subtitle,
                    style: TextStyle(
                      color: perk.dark ? Colors.white70 : AppColors.green,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberPricesSection extends StatelessWidget {
  const _MemberPricesSection();

  static const items = <_MemberPriceItem>[
    _MemberPriceItem(
      name: 'Iced Latte',
      subtitle: 'Smooth & classic',
      regularPrice: 'EGP 75',
      memberPrice: 'EGP 60',
      image: 'assets/images/products/iced_latte.png',
    ),
    _MemberPriceItem(
      name: 'Pistachio Latte',
      subtitle: 'Rich & nutty',
      regularPrice: 'EGP 85',
      memberPrice: 'EGP 68',
      image: 'assets/images/products/pistachio_latte.png',
    ),
    _MemberPriceItem(
      name: 'Turkey Sandwich',
      subtitle: 'Fresh & satisfying',
      regularPrice: 'EGP 95',
      memberPrice: 'EGP 76',
      image: 'assets/images/products/turkey_cheese_sandwich.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionTitle(
          title: 'Member Prices This Month',
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 212,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 190,
                child: _MemberPriceCard(
                  item: items[index],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MemberPriceCard extends StatelessWidget {
  final _MemberPriceItem item;

  const _MemberPriceCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  item.image,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 11.5,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.2,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            item.regularPrice,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.memberPrice,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.beige,
                  size: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.beige,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Member Price',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 8.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyJoinCard extends StatelessWidget {
  const _WhyJoinCard();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EEE8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: compact
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.green,
                      size: 27,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Why Join?',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 9),
                Text(
                  'Save up to EGP 280/month',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Faster rewards, better prices, premium perks.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.2,
                  ),
                ),
              ],
            )
          : const Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.green,
                  size: 27,
                ),
                SizedBox(width: 11),
                Text(
                  'Why Join?',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 1,
                  height: 34,
                  child: ColoredBox(color: AppColors.green),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save up to EGP 280/month',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Faster rewards, better prices, premium perks.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 9.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _StickyMembershipAction extends StatelessWidget {
  final String label;
  final String billingCycle;
  final bool active;

  const _StickyMembershipAction({
    required this.label,
    required this.billingCycle,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () async {
                final store = CustomerMembershipStore.instance;
                if (store.usesApi) {
                  await store.refresh();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        store.tierName == null
                            ? 'Your GETIN membership tier is based on your loyalty activity.'
                            : 'Current GETIN tier: ${store.tierName}.',
                      ),
                    ),
                  );
                  return;
                }
                if (!active) {
                  store.activate(billingCycle: billingCycle);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      active
                          ? 'Getin Membership is active.'
                          : 'Demo membership activated. You now earn 1.5× Stars on eligible orders.',
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.beige,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Cancel anytime · Terms apply',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 8.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const Text(
          'See All',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 2),
        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.green,
          size: 18,
        ),
      ],
    );
  }
}

class _MembershipBenefit {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MembershipBenefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _MonthlyPerk {
  final String title;
  final String subtitle;
  final String image;
  final bool dark;

  const _MonthlyPerk({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.dark,
  });
}

class _MemberPriceItem {
  final String name;
  final String subtitle;
  final String regularPrice;
  final String memberPrice;
  final String image;

  const _MemberPriceItem({
    required this.name,
    required this.subtitle,
    required this.regularPrice,
    required this.memberPrice,
    required this.image,
  });
}
