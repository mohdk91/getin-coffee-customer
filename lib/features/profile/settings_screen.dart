import 'package:flutter/material.dart';

import '../../core/customer/customer_country.dart';
import '../../core/settings/customer_settings_store.dart';
import '../../core/theme/app_colors.dart';
import 'profile_pages.dart';
import 'settings_detail_screens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final store = CustomerSettingsStore.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([
        store,
        CustomerCountryStore.current,
      ]),
      builder: (context, _) {
        final country = CustomerCountryStore.current.value;
        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.green,
            elevation: 0,
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                _SettingsGroup(
                  title: 'Account',
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Personal Information',
                      onTap: () => _push(
                        context,
                        const PersonalInformationScreen(),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.phone_iphone_rounded,
                      label: 'Phone Number',
                      subtitle: store.phone,
                      onTap: () => _push(
                        context,
                        const PhoneNumberSettingsScreen(),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      subtitle: store.email,
                      onTap: () => _push(
                        context,
                        const EmailSettingsScreen(),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.location_on_outlined,
                      label: 'Saved Addresses',
                      onTap: () => _push(
                        context,
                        const SavedAddressesScreen(),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.credit_card_rounded,
                      label: 'Payment Methods',
                      onTap: () => _push(
                        context,
                        const PaymentMethodsScreen(),
                      ),
                      last: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsGroup(
                  title: 'App Preferences',
                  children: [
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications',
                      subtitle:
                          '${store.enabledNotificationCount}/${CustomerSettingsStore.notificationKeys.length} enabled',
                      onTap: () => _push(
                        context,
                        const SettingsNotificationsScreen(),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      label: 'Language',
                      subtitle: store.language,
                      onTap: () => _push(
                        context,
                        const SettingsLanguageScreen(),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.public_rounded,
                      label: 'Country',
                      subtitle: '${country.flagEmoji} ${country.name}',
                      onTap: () => _push(
                        context,
                        const SettingsCountryScreen(),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.brightness_6_outlined,
                      label: 'Appearance',
                      subtitle: store.appearance,
                      onTap: () => _push(
                        context,
                        const SettingsAppearanceScreen(),
                      ),
                      last: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsGroup(
                  title: 'Privacy & Security',
                  children: [
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Security',
                      subtitle: store.biometricLogin
                          ? 'Biometrics enabled · sessions'
                          : 'Password, biometrics and sessions',
                      onTap: () => _push(
                        context,
                        const SettingsSecurityScreen(),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy',
                      subtitle: 'Location, personalization and data',
                      onTap: () => _push(
                        context,
                        const SettingsPrivacyScreen(),
                      ),
                      last: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsGroup(
                  title: 'Support & Legal',
                  children: [
                    _SettingsTile(
                      icon: Icons.support_agent_rounded,
                      label: 'Help & Support',
                      subtitle: store.supportRequests.isEmpty
                          ? 'Orders, payments, delivery and account'
                          : '${store.supportRequests.length} demo request${store.supportRequests.length == 1 ? '' : 's'}',
                      onTap: () => _push(
                        context,
                        const SettingsHelpSupportScreen(),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'About Getin',
                      onTap: () => _push(
                        context,
                        const SettingsAboutScreen(),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.description_outlined,
                      label: 'Terms & Conditions',
                      onTap: () => _push(
                        context,
                        const SettingsLegalScreen(
                          type: SettingsLegalType.terms,
                        ),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.policy_outlined,
                      label: 'Privacy Policy',
                      onTap: () => _push(
                        context,
                        const SettingsLegalScreen(
                          type: SettingsLegalType.privacy,
                        ),
                      ),
                      last: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsGroup(
                  title: 'Account Actions',
                  children: [
                    _SettingsTile(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete Account',
                      subtitle: store.deleteRequestedAt == null
                          ? 'Demo confirmation flow'
                          : 'Demo deletion request recorded',
                      danger: true,
                      onTap: () => _push(
                        context,
                        const SettingsDeleteAccountScreen(),
                      ),
                      last: true,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () => showSettingsLogoutSheet(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB94A48),
                      side: const BorderSide(color: Color(0xFFE7B9B6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Task #16 uses real local/demo interactions. Backend authentication, push, localization, legal CMS and data-management APIs remain intentionally unconnected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
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

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool last;
  final bool danger;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.last = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB94A48) : AppColors.green;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: danger ? const Color(0xFFFCEDEC) : AppColors.cream,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
          ),
          onTap: onTap,
        ),
        if (!last)
          const Divider(
            height: 1,
            indent: 68,
            color: AppColors.border,
          ),
      ],
    );
  }
}
