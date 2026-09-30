import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/customer/customer_country.dart';
import '../../core/settings/customer_settings_store.dart';
import '../../core/theme/app_colors.dart';
import '../cart/cart_controller.dart';
import '../chat/customer_support_chat_screen.dart';
import '../auth/sign_in_screen.dart';

class PhoneNumberSettingsScreen extends StatefulWidget {
  const PhoneNumberSettingsScreen({super.key});

  @override
  State<PhoneNumberSettingsScreen> createState() =>
      _PhoneNumberSettingsScreenState();
}

class _PhoneNumberSettingsScreenState extends State<PhoneNumberSettingsScreen> {
  late final TextEditingController _controller;
  String _phoneCode = '+20';
  String _phoneFlag = '🇪🇬';

  @override
  void initState() {
    super.initState();
    final saved = CustomerSettingsStore.instance.phone.trim();
    final local = saved.startsWith('+20') ? saved.substring(3).trim() : saved;
    _controller = TextEditingController(text: local);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectCountry() async {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        inputDecoration: InputDecoration(
          labelText: 'Search country or dial code',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onSelect: (country) {
        setState(() {
          _phoneCode = '+${country.phoneCode}';
          _phoneFlag = country.flagEmoji;
        });
      },
    );
  }

  Future<void> _save() async {
    final local = _controller.text.trim();
    final value = '$_phoneCode $local';
    if (local.replaceAll(RegExp(r'[^0-9]'), '').length < 7) {
      _showSnack(context, 'Enter a valid demo phone number.');
      return;
    }
    final confirmed = await _showDemoVerification(
      context,
      title: 'Verify phone number',
      destination: value,
    );
    if (!confirmed || !mounted) {
      return;
    }
    await CustomerSettingsStore.instance.setPhone(value);
    if (!mounted) {
      return;
    }
    _showSnack(context, 'Phone number verified and saved for this demo.');
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsPage(
      title: 'Phone Number',
      children: [
        const _InfoCard(
          icon: Icons.verified_user_outlined,
          title: 'Verified contact',
          text:
              'The production flow will verify a new number using OTP before replacing the current number.',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.phone,
          decoration: _fieldDecoration(
            label: 'Phone number',
            icon: Icons.phone_iphone_rounded,
          ).copyWith(
            prefixIconConstraints: const BoxConstraints(minWidth: 104),
            prefixIcon: InkWell(
              onTap: _selectCountry,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_phoneFlag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      _phoneCode,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          icon: Icons.sms_outlined,
          label: 'Verify & Save Number',
          onPressed: _save,
        ),
      ],
    );
  }
}

class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: CustomerSettingsStore.instance.email,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (!value.contains('@') || !value.contains('.')) {
      _showSnack(context, 'Enter a valid demo email address.');
      return;
    }
    final confirmed = await _showDemoVerification(
      context,
      title: 'Verify email address',
      destination: value,
    );
    if (!confirmed || !mounted) {
      return;
    }
    await CustomerSettingsStore.instance.setEmail(value);
    if (!mounted) {
      return;
    }
    _showSnack(context, 'Email verified and saved for this demo.');
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsPage(
      title: 'Email',
      children: [
        const _InfoCard(
          icon: Icons.mark_email_read_outlined,
          title: 'Verified contact',
          text:
              'The production flow will require email verification before the account email changes.',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.emailAddress,
          decoration: _fieldDecoration(
            label: 'Email address',
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          icon: Icons.mark_email_read_outlined,
          label: 'Verify & Save Email',
          onPressed: _save,
        ),
      ],
    );
  }
}

class SettingsNotificationsScreen extends StatelessWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CustomerSettingsStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return _SettingsPage(
          title: 'Notifications',
          children: [
            _SwitchSection(
              title: 'Order Updates',
              labels: const ['Order status', 'Driver updates'],
              store: store,
            ),
            const SizedBox(height: 14),
            _SwitchSection(
              title: 'Rewards',
              labels: const ['Stars & rewards', 'Voucher expiry'],
              store: store,
            ),
            const SizedBox(height: 14),
            _SwitchSection(
              title: 'Offers',
              labels: const [
                'Offers & promotions',
                'New products',
                'Member-only offers',
              ],
              store: store,
            ),
            const SizedBox(height: 14),
            _SwitchSection(
              title: 'Account',
              labels: const ['Security alerts', 'Payment alerts'],
              store: store,
            ),
            const SizedBox(height: 14),
            const _InfoCard(
              icon: Icons.info_outline_rounded,
              title: 'Demo preference storage',
              text:
                  'These switches persist locally. Push-notification registration and mandatory service notifications will connect to the backend/provider later.',
            ),
          ],
        );
      },
    );
  }
}

class SettingsLanguageScreen extends StatelessWidget {
  const SettingsLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CustomerSettingsStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => _SettingsPage(
        title: 'Language',
        children: [
          for (final option in const <(String, String, String)>[
            ('🇬🇧', 'English', 'English'),
            ('🇪🇬', 'العربية', 'Arabic'),
            ('🇫🇷', 'Français', 'French'),
            ('🇪🇸', 'Español', 'Spanish'),
            ('🇮🇹', 'Italiano', 'Italian'),
            ('🇹🇷', 'Türkçe', 'Turkish'),
            ('🇨🇳', '简体中文', 'Simplified Chinese'),
          ].where((option) => store.availableLanguages.contains(option.$2))) ...[
            _RadioCard(
              label: '${option.$1}  ${option.$2}',
              subtitle: option.$3,
              selected: store.language == option.$2,
              onTap: () => store.setLanguage(option.$2),
            ),
            const SizedBox(height: 9),
          ],
          const SizedBox(height: 5),
          _InfoCard(
            icon: Icons.translate_rounded,
            title: store.usesApi ? 'Account preference' : 'Saved locally for the demo',
            text: store.usesApi
                ? 'English and Arabic are synced with your GETIN account. Full application-wide translation is completed in the localization phase.'
                : 'The preference is functional and persistent. Full application-wide localization will be connected when the translation layer is added.',
          ),
        ],
      ),
    );
  }
}

class SettingsCountryScreen extends StatefulWidget {
  const SettingsCountryScreen({super.key});

  @override
  State<SettingsCountryScreen> createState() => _SettingsCountryScreenState();
}

class _SettingsCountryScreenState extends State<SettingsCountryScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _select(CustomerCountry country) async {
    final current = CustomerCountryStore.current.value;
    if (country.normalizedIsoCode == current.normalizedIsoCode) {
      return;
    }

    final hasCart = CartController.instance.isNotEmpty;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Change country to ${country.name}?'),
            content: Text(
              hasCart
                  ? 'Your cart has items. Country can affect currency, branches, product availability and delivery. This demo will keep your cart so nothing is silently deleted; it must be revalidated before a real order.'
                  : 'Country can affect currency, branches, product availability and delivery. The demo will save your selection locally.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Change Country'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }
    await CustomerCountryStore.setCountry(country);
    if (!mounted) {
      return;
    }
    setState(() {});
    _showSnack(context, '${country.flagEmoji} ${country.name} saved.');
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final countries = CustomerCountryCatalog.all.where((country) {
      return country.name.toLowerCase().contains(query) ||
          country.normalizedIsoCode.toLowerCase().contains(query);
    }).toList();

    return ValueListenableBuilder<CustomerCountry>(
      valueListenable: CustomerCountryStore.current,
      builder: (context, selected, _) => _SettingsPage(
        title: 'Country',
        children: [
          _InfoCard(
            icon: Icons.public_rounded,
            title: '${selected.flagEmoji} ${selected.name}',
            text:
                'Current customer country. This same selection is used by the Profile country flag.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: _fieldDecoration(
              label: 'Search countries',
              icon: Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 12),
          ...countries.take(40).map(
                (country) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RadioCard(
                    label: '${country.flagEmoji} ${country.name}',
                    subtitle: country.normalizedIsoCode,
                    selected:
                        country.normalizedIsoCode == selected.normalizedIsoCode,
                    onTap: () => _select(country),
                  ),
                ),
              ),
          if (countries.length > 40)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Keep typing to narrow the country list.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsAppearanceScreen extends StatelessWidget {
  const SettingsAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CustomerSettingsStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final darkPreview = store.appearance == 'Dark';
        return _SettingsPage(
          title: 'Appearance',
          children: [
            ...<String>['System Default', 'Light', 'Dark'].map(
              (value) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _RadioCard(
                  label: value,
                  selected: store.appearance == value,
                  onTap: () => store.setAppearance(value),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: darkPreview ? AppColors.greenDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: TextStyle(
                      color: darkPreview ? AppColors.beige : AppColors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${store.appearance} preference is saved locally.',
                    style: TextStyle(
                      color: darkPreview ? Colors.white70 : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _InfoCard(
              icon: Icons.brightness_6_outlined,
              title: 'Theme integration ready',
              text:
                  'The preference is testable now. We keep the existing Getin screen styling unchanged until every screen has a complete production dark theme.',
            ),
          ],
        );
      },
    );
  }
}

class SettingsSecurityScreen extends StatelessWidget {
  const SettingsSecurityScreen({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();
    final saved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Change password · demo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newPassword,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                ),
                TextField(
                  controller: confirmPassword,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final valid = newPassword.text.length >= 8 &&
                      newPassword.text == confirmPassword.text;
                  if (!valid) {
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;
    newPassword.dispose();
    confirmPassword.dispose();
    if (!saved) {
      return;
    }
    await CustomerSettingsStore.instance.markPasswordChanged();
    if (context.mounted) {
      _showSnack(context, 'Password change recorded for this local demo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = CustomerSettingsStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => _SettingsPage(
        title: 'Security',
        children: [
          _ActionCard(
            icon: Icons.password_rounded,
            title: 'Change Password',
            subtitle: store.lastPasswordChangedAt == null
                ? 'No demo change recorded'
                : 'Changed in this demo session',
            onTap: () => _changePassword(context),
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.phone_iphone_rounded,
            title: 'Phone Number',
            subtitle: store.phone,
            onTap: () => _push(context, const PhoneNumberSettingsScreen()),
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: store.email,
            onTap: () => _push(context, const EmailSettingsScreen()),
          ),
          const SizedBox(height: 8),
          _SwitchCard(
            icon: Icons.fingerprint_rounded,
            title: 'Biometric Login',
            subtitle: 'Local demo preference for Face ID / fingerprint',
            value: store.biometricLogin,
            onChanged: store.setBiometricLogin,
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Sessions & Devices'),
          const SizedBox(height: 9),
          const _SessionCard(
            icon: Icons.smartphone_rounded,
            title: 'Android Device',
            subtitle: 'Current demo session',
            current: true,
          ),
          if (store.otherDemoSessionActive) ...[
            const SizedBox(height: 8),
            const _SessionCard(
              icon: Icons.laptop_mac_rounded,
              title: 'Chrome on Mac',
              subtitle: 'Demo session · last active 2 hours ago',
            ),
            const SizedBox(height: 12),
            _DangerButton(
              label: 'Sign Out Other Devices',
              onPressed: () async {
                await store.signOutOtherDemoSessions();
                if (context.mounted) {
                  _showSnack(context, 'Other demo sessions signed out.');
                }
              },
            ),
          ] else ...[
            const SizedBox(height: 8),
            const _InfoCard(
              icon: Icons.verified_user_outlined,
              title: 'No other demo sessions',
              text: 'Only the current device remains active.',
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsPrivacyScreen extends StatelessWidget {
  const SettingsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CustomerSettingsStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => _SettingsPage(
        title: 'Privacy',
        children: [
          _SwitchCard(
            icon: Icons.location_on_outlined,
            title: 'Location',
            subtitle:
                'Demo preference for nearby branches and delivery availability',
            value: store.locationAccess,
            onChanged: store.setLocationAccess,
          ),
          const SizedBox(height: 8),
          _SwitchCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Personalized Recommendations',
            value: store.personalizedRecommendations,
            onChanged: store.setPersonalizedRecommendations,
          ),
          const SizedBox(height: 8),
          _SwitchCard(
            icon: Icons.campaign_outlined,
            title: 'Marketing Personalization',
            value: store.marketingPersonalization,
            onChanged: store.setMarketingPersonalization,
          ),
          const SizedBox(height: 8),
          _SwitchCard(
            icon: Icons.analytics_outlined,
            title: 'Analytics',
            value: store.analytics,
            onChanged: store.setAnalytics,
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.download_outlined,
            title: 'Download My Data',
            subtitle: store.lastDataExportAt == null
                ? 'Create a local demo export request'
                : 'Demo export request created',
            onTap: () async {
              await store.requestDataExport();
              if (context.mounted) {
                _showSnack(
                  context,
                  'Demo data-export request created. Backend export is not connected yet.',
                );
              }
            },
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            onTap: () => _push(
              context,
              const SettingsLegalScreen(type: SettingsLegalType.privacy),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsHelpSupportScreen extends StatelessWidget {
  const SettingsHelpSupportScreen({super.key});

  static const topics = <(String, IconData, String)>[
    (
      'Order Issue',
      Icons.receipt_long_outlined,
      'Select the affected order and tell us what went wrong',
    ),
    (
      'Payment Issue',
      Icons.credit_card_rounded,
      'Select the affected order/payment and payment problem',
    ),
    (
      'Delivery Issue',
      Icons.delivery_dining_rounded,
      'Select the delivery order and delivery problem',
    ),
    (
      'Rewards & Membership',
      Icons.stars_outlined,
      'Rewards, vouchers, membership or gift cards',
    ),
    (
      'Account',
      Icons.person_outline_rounded,
      'Login, profile, phone, email or account security',
    ),
    (
      'Technical Problem',
      Icons.bug_report_outlined,
      'App, loading, notification or device-related problem',
    ),
    (
      'Other',
      Icons.more_horiz_rounded,
      'Anything that does not fit the topics above',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final store = CustomerSettingsStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => _SettingsPage(
        title: 'Help & Support',
        children: [
          const _InfoCard(
            icon: Icons.link_rounded,
            title: 'Attach the right context first',
            text:
                'For order, payment and delivery issues, choose the affected order first. The support request will keep that order context so the customer does not need to explain it again.',
          ),
          const SizedBox(height: 18),
          const _SectionTitle('How can we help?'),
          const SizedBox(height: 9),
          ...topics.map(
            (topic) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActionCard(
                icon: topic.$2,
                title: topic.$1,
                subtitle: topic.$3,
                onTap: () => _push(
                  context,
                  SettingsSupportRequestScreen(topic: topic.$1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const _SectionTitle('Contact Getin'),
          const SizedBox(height: 9),
          _ActionCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat with Getin',
            subtitle: 'Start a general support conversation',
            onTap: () => _push(
              context,
              const CustomerSupportChatScreen(),
            ),
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@getin.coffee',
            onTap: () async {
              await Clipboard.setData(
                const ClipboardData(text: 'support@getin.coffee'),
              );
              if (context.mounted) {
                _showSnack(context, 'Support email copied.');
              }
            },
          ),
          if (store.supportRequests.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _SectionTitle('Your Support Requests'),
            const SizedBox(height: 9),
            ...store.supportRequests.take(5).map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _InfoCard(
                      icon: Icons.confirmation_number_outlined,
                      title: '${request.id} · ${request.status}',
                      text: [
                        request.topic,
                        if (request.contextSummary.isNotEmpty)
                          request.contextSummary,
                        request.message,
                      ].join('\n'),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class SettingsSupportRequestScreen extends StatefulWidget {
  final String topic;

  const SettingsSupportRequestScreen({
    super.key,
    required this.topic,
  });

  @override
  State<SettingsSupportRequestScreen> createState() =>
      _SettingsSupportRequestScreenState();
}

class _SettingsSupportRequestScreenState
    extends State<SettingsSupportRequestScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedContextId;
  String? _selectedContextLabel;
  String? _selectedIssueType;
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  bool get _isOrderTopic =>
      widget.topic == 'Order Issue' ||
      widget.topic == 'Payment Issue' ||
      widget.topic == 'Delivery Issue';

  bool get _requiresContext =>
      _isOrderTopic ||
      widget.topic == 'Rewards & Membership' ||
      widget.topic == 'Account' ||
      widget.topic == 'Technical Problem';

  List<_SupportOrderRef> get _orders {
    final cart = CartController.instance;
    final branchName =
        cart.cartBranchName ?? cart.currentBranchName ?? 'Getin Stanley';
    final all = <_SupportOrderRef>[
      _SupportOrderRef(
        id: 'GC-10582',
        branchName: branchName,
        fulfillment: 'Delivery',
        status: 'Out for delivery',
        placedAt: '19 Sep · 2:14 PM',
        total: 'EGP 245',
      ),
      _SupportOrderRef(
        id: 'GC-10491',
        branchName: branchName,
        fulfillment: 'Pickup',
        status: 'Completed',
        placedAt: '18 Sep · 9:35 AM',
        total: 'EGP 135',
      ),
      _SupportOrderRef(
        id: 'GC-10376',
        branchName: branchName,
        fulfillment: 'Delivery',
        status: 'Cancelled',
        placedAt: '16 Sep · 6:08 PM',
        total: 'EGP 75',
      ),
    ];
    if (widget.topic == 'Delivery Issue') {
      return all.where((order) => order.fulfillment == 'Delivery').toList();
    }
    return all;
  }

  List<_SupportContextOption> get _contextOptions => switch (widget.topic) {
        'Rewards & Membership' => const <_SupportContextOption>[
            _SupportContextOption(
              id: 'rewards',
              label: 'Stars & Rewards',
              subtitle: 'Earning, redeeming or using rewards',
              icon: Icons.stars_outlined,
            ),
            _SupportContextOption(
              id: 'vouchers',
              label: 'Vouchers',
              subtitle: 'Voucher eligibility, applying or expiry',
              icon: Icons.confirmation_number_outlined,
            ),
            _SupportContextOption(
              id: 'membership',
              label: 'Getin Membership',
              subtitle: 'Benefits, member pricing or membership status',
              icon: Icons.workspace_premium_outlined,
            ),
            _SupportContextOption(
              id: 'gift_cards',
              label: 'Gift Cards',
              subtitle: 'Gift card purchase, redemption or balance',
              icon: Icons.card_giftcard_outlined,
            ),
          ],
        'Account' => const <_SupportContextOption>[
            _SupportContextOption(
              id: 'login',
              label: 'Sign in & access',
              subtitle: 'Login, password or verification',
              icon: Icons.login_rounded,
            ),
            _SupportContextOption(
              id: 'profile',
              label: 'Personal information',
              subtitle: 'Name, birthday, country or profile photo',
              icon: Icons.person_outline_rounded,
            ),
            _SupportContextOption(
              id: 'contact',
              label: 'Phone or email',
              subtitle: 'Changing or verifying contact details',
              icon: Icons.contact_mail_outlined,
            ),
            _SupportContextOption(
              id: 'security',
              label: 'Security',
              subtitle: 'Password, biometric login or sessions',
              icon: Icons.security_outlined,
            ),
          ],
        'Technical Problem' => const <_SupportContextOption>[
            _SupportContextOption(
              id: 'crash',
              label: 'App crash / freeze',
              subtitle: 'App closes, freezes or stops responding',
              icon: Icons.warning_amber_rounded,
            ),
            _SupportContextOption(
              id: 'loading',
              label: 'Loading / connection',
              subtitle: 'Screen or content does not load',
              icon: Icons.sync_problem_rounded,
            ),
            _SupportContextOption(
              id: 'notifications',
              label: 'Notifications',
              subtitle: 'Missing or incorrect notifications',
              icon: Icons.notifications_none_rounded,
            ),
            _SupportContextOption(
              id: 'camera',
              label: 'Camera / photo',
              subtitle: 'Profile photo, camera or gallery issue',
              icon: Icons.camera_alt_outlined,
            ),
            _SupportContextOption(
              id: 'other_technical',
              label: 'Other technical issue',
              subtitle: 'Another app or device problem',
              icon: Icons.devices_other_rounded,
            ),
          ],
        _ => const <_SupportContextOption>[],
      };

  List<String> get _issueTypes => switch (widget.topic) {
        'Order Issue' => const <String>[
            'Missing item',
            'Wrong item',
            'Product quality',
            'Change or cancel order',
            'Order cancelled unexpectedly',
            'Other order issue',
          ],
        'Payment Issue' => const <String>[
            'Charged but order failed',
            'Charged twice',
            'Wrong amount charged',
            'Refund not received',
            'Card/payment declined',
            'Cash payment issue',
            'Other payment issue',
          ],
        'Delivery Issue' => const <String>[
            'Driver is late',
            'Marked delivered but not received',
            'Wrong delivery address',
            'Driver/contact problem',
            'Delivery fee problem',
            'Order arrived damaged',
            'Other delivery issue',
          ],
        'Rewards & Membership' => const <String>[
            'Balance/status is wrong',
            'Cannot redeem or apply',
            'Benefit not received',
            'Charge or renewal question',
            'Other rewards/membership issue',
          ],
        'Account' => const <String>[
            'Cannot access account',
            'Verification problem',
            'Information is incorrect',
            'Security concern',
            'Other account issue',
          ],
        'Technical Problem' => const <String>[
            'Always happens',
            'Happens sometimes',
            'Started after an update',
            'Only on one screen',
            'Other technical behavior',
          ],
        _ => const <String>[],
      };

  String get _contextTitle => switch (widget.topic) {
        'Order Issue' => '1. Which order has a problem?',
        'Payment Issue' => '1. Which order/payment has a problem?',
        'Delivery Issue' => '1. Which delivery order has a problem?',
        'Rewards & Membership' => '1. What needs help?',
        'Account' => '1. Which account area?',
        'Technical Problem' => '1. What is affected?',
        _ => '',
      };

  String get _introText => switch (widget.topic) {
        'Order Issue' =>
          'Choose the affected order first. Its order number, branch, status and fulfillment type will be attached to the request.',
        'Payment Issue' =>
          'Choose the order related to the charge or refund. If the problem is only with a saved card, use the payment-method option below.',
        'Delivery Issue' =>
          'Only delivery orders are shown here. Choose the delivery first so support knows the exact order and status.',
        'Rewards & Membership' =>
          'Choose the benefit or balance that is affected before describing the problem.',
        'Account' =>
          'Choose the account area so the request reaches the right support context.',
        'Technical Problem' =>
          'Choose what is affected. App/device diagnostics can be attached by the backend later.',
        'Chat with Getin' =>
          'Use this for a general support question that is not tied to a specific order.',
        _ => 'Tell us what happened and include the important details.',
      };

  bool get _canSubmit {
    if (_messageController.text.trim().isEmpty) {
      return false;
    }
    if (_requiresContext && _selectedContextId == null) {
      return false;
    }
    if (_issueTypes.isNotEmpty && _selectedIssueType == null) {
      return false;
    }
    return !_submitting;
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }
    setState(() => _submitting = true);
    final request = await CustomerSettingsStore.instance.addSupportRequest(
      topic: widget.topic,
      message: _messageController.text,
      contextId: _selectedContextId,
      contextLabel: _selectedContextLabel,
      issueType: _selectedIssueType,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Support request created'),
        content: Text(
          'Reference ${request.id}\n\n${request.contextSummary.isEmpty ? widget.topic : request.contextSummary}\n\nThis is a local demo request. The production app will send the attached context to the support backend.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderOptions = _orders;
    final contextOptions = _contextOptions;
    final issueTypes = _issueTypes;

    return _SettingsPage(
      title: widget.topic,
      children: [
        _InfoCard(
          icon: _supportTopicIcon(widget.topic),
          title: 'We will attach the relevant context',
          text: _introText,
        ),
        if (_requiresContext) ...[
          const SizedBox(height: 18),
          _SectionTitle(_contextTitle),
          const SizedBox(height: 9),
          if (_isOrderTopic) ...[
            ...orderOptions.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SupportOrderCard(
                  order: order,
                  selected: _selectedContextId == order.id,
                  onTap: () {
                    setState(() {
                      _selectedContextId = order.id;
                      _selectedContextLabel =
                          'Order ${order.id} · ${order.fulfillment} · ${order.status}';
                    });
                  },
                ),
              ),
            ),
            if (widget.topic == 'Payment Issue')
              _SupportChoiceCard(
                icon: Icons.credit_card_rounded,
                title: 'Saved card / payment method',
                subtitle: 'The payment problem is not tied to an order',
                selected: _selectedContextId == 'payment_method',
                onTap: () {
                  setState(() {
                    _selectedContextId = 'payment_method';
                    _selectedContextLabel = 'Saved card / payment method';
                  });
                },
              ),
          ] else ...[
            ...contextOptions.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SupportChoiceCard(
                  icon: option.icon,
                  title: option.label,
                  subtitle: option.subtitle,
                  selected: _selectedContextId == option.id,
                  onTap: () {
                    setState(() {
                      _selectedContextId = option.id;
                      _selectedContextLabel = option.label;
                    });
                  },
                ),
              ),
            ),
          ],
        ],
        if (issueTypes.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionTitle('2. What is the problem?'),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: issueTypes
                .map(
                  (issue) => ChoiceChip(
                    label: Text(issue),
                    selected: _selectedIssueType == issue,
                    onSelected: (_) {
                      setState(() => _selectedIssueType = issue);
                    },
                    selectedColor: AppColors.beige,
                    side: BorderSide(
                      color: _selectedIssueType == issue
                          ? AppColors.green
                          : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      color: AppColors.green,
                      fontWeight: _selectedIssueType == issue
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 18),
        _SectionTitle(issueTypes.isEmpty
            ? 'Tell us what happened'
            : '3. Tell us what happened'),
        const SizedBox(height: 9),
        TextField(
          controller: _messageController,
          minLines: 4,
          maxLines: 7,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.newline,
          decoration: _fieldDecoration(
            label: 'Add details',
            icon: Icons.edit_note_rounded,
          ).copyWith(
            hintText:
                'What happened, what did you expect, and anything else support should know?',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _canSubmit ? _submit : null,
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_submitting ? 'Submitting…' : 'Submit Support Request'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Local demo only. Production requests will attach authenticated customer/order context and be sent to the support backend.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _SupportOrderRef {
  final String id;
  final String branchName;
  final String fulfillment;
  final String status;
  final String placedAt;
  final String total;

  const _SupportOrderRef({
    required this.id,
    required this.branchName,
    required this.fulfillment,
    required this.status,
    required this.placedAt,
    required this.total,
  });
}

class _SupportContextOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;

  const _SupportContextOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

class _SupportOrderCard extends StatelessWidget {
  final _SupportOrderRef order;
  final bool selected;
  final VoidCallback onTap;

  const _SupportOrderCard({
    required this.order,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.beige.withOpacity(0.5) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? AppColors.green : AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  order.fulfillment == 'Delivery'
                      ? Icons.delivery_dining_rounded
                      : Icons.shopping_bag_outlined,
                  color: selected ? AppColors.beige : AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Order ${order.id}',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.green,
                            size: 22,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.branchName} · ${order.fulfillment}',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.placedAt} · ${order.status} · ${order.total}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        height: 1.3,
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

class _SupportChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SupportChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.beige.withOpacity(0.5) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? AppColors.green : AppColors.cream,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.beige : AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? AppColors.green : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _supportTopicIcon(String topic) => switch (topic) {
      'Order Issue' => Icons.receipt_long_outlined,
      'Payment Issue' => Icons.credit_card_rounded,
      'Delivery Issue' => Icons.delivery_dining_rounded,
      'Rewards & Membership' => Icons.stars_outlined,
      'Account' => Icons.person_outline_rounded,
      'Technical Problem' => Icons.bug_report_outlined,
      'Chat with Getin' => Icons.chat_bubble_outline_rounded,
      _ => Icons.help_outline_rounded,
    };

class SettingsAboutScreen extends StatelessWidget {
  const SettingsAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsPage(
      title: 'About Getin',
      children: [
        Center(
          child: Column(
            children: [
              Image.asset('assets/images/getin_logo_mark.png', height: 80),
              const SizedBox(height: 10),
              const Text(
                'Getin Coffee',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Good coffee. Good days.',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _InfoCard(
          icon: Icons.auto_stories_outlined,
          title: 'Our Story',
          text:
              'This demo keeps About content local so the screen is fully testable. Production content can later come from the Getin CMS/backend.',
        ),
        const SizedBox(height: 8),
        const _InfoCard(
          icon: Icons.coffee_rounded,
          title: 'Our Coffee',
          text:
              'Explore Getin through branch-specific menus, rewards, membership and ordering experiences.',
        ),
        const SizedBox(height: 8),
        _ActionCard(
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          onTap: () => _push(
            context,
            const SettingsLegalScreen(type: SettingsLegalType.terms),
          ),
        ),
        const SizedBox(height: 8),
        _ActionCard(
          icon: Icons.policy_outlined,
          title: 'Privacy Policy',
          onTap: () => _push(
            context,
            const SettingsLegalScreen(type: SettingsLegalType.privacy),
          ),
        ),
        const SizedBox(height: 8),
        _ActionCard(
          icon: Icons.workspace_premium_outlined,
          title: 'Membership Terms',
          onTap: () => _push(
            context,
            const SettingsLegalScreen(type: SettingsLegalType.membership),
          ),
        ),
        const SizedBox(height: 8),
        _ActionCard(
          icon: Icons.stars_outlined,
          title: 'Rewards Terms',
          onTap: () => _push(
            context,
            const SettingsLegalScreen(type: SettingsLegalType.rewards),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'App Version 1.0.0 (1) · Local Demo',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

enum SettingsLegalType { terms, privacy, membership, rewards }

class SettingsLegalScreen extends StatelessWidget {
  final SettingsLegalType type;

  const SettingsLegalScreen({
    super.key,
    required this.type,
  });

  String get _title => switch (type) {
        SettingsLegalType.terms => 'Terms & Conditions',
        SettingsLegalType.privacy => 'Privacy Policy',
        SettingsLegalType.membership => 'Membership Terms',
        SettingsLegalType.rewards => 'Rewards Terms',
      };

  String get _body => switch (type) {
        SettingsLegalType.terms =>
          'These are local demo terms for testing navigation and layout. Production terms must be loaded from the approved Getin legal/CMS source before release.\n\nOrders, availability, pricing, delivery, payment and refunds will follow the rules configured for the customer country and selected branch.',
        SettingsLegalType.privacy =>
          'This local demo stores selected preferences, demo cards, addresses and feature state on the device for testing. Production privacy text, retention rules and data-subject workflows must come from Getin’s approved legal policy and backend implementation.',
        SettingsLegalType.membership =>
          'Membership benefits shown in this demo are illustrative. Production eligibility, pricing, renewal, member prices, Stars and benefit conditions must be provided by the membership backend and approved terms.',
        SettingsLegalType.rewards =>
          'Rewards in this demo use local Stars and redemption state for testing. Production earning, expiry, eligibility and redemption rules must be validated by the rewards backend.',
      };

  @override
  Widget build(BuildContext context) {
    return _SettingsPage(
      title: _title,
      children: [
        _InfoCard(
          icon: Icons.gavel_rounded,
          title: 'Local demo content',
          text: _body,
        ),
      ],
    );
  }
}

class SettingsDeleteAccountScreen extends StatefulWidget {
  const SettingsDeleteAccountScreen({super.key});

  @override
  State<SettingsDeleteAccountScreen> createState() =>
      _SettingsDeleteAccountScreenState();
}

class _SettingsDeleteAccountScreenState
    extends State<SettingsDeleteAccountScreen> {
  final TextEditingController _confirmation = TextEditingController();
  bool _canDelete = false;

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_canDelete) {
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirm demo account deletion'),
            content: const Text(
              'This records a local demo deletion request and returns to Sign In. It does not erase your device data or call a backend.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB94A48),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete Demo Account'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    await CustomerSettingsStore.instance.requestDeleteAccount();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsPage(
      title: 'Delete Account',
      children: [
        const _InfoCard(
          icon: Icons.warning_amber_rounded,
          title: 'This action is destructive in production',
          text:
              'A production deletion flow should verify the customer, request backend deletion and retain only records required by law. This task simulates the interaction locally without deleting your test data.',
          danger: true,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmation,
          onChanged: (value) {
            final canDelete = value.trim().toUpperCase() == 'DELETE';
            if (canDelete != _canDelete) {
              setState(() => _canDelete = canDelete);
            }
          },
          decoration: _fieldDecoration(
            label: 'Type DELETE to continue',
            icon: Icons.delete_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),
        _DangerButton(
          label: 'Delete Demo Account',
          onPressed: _canDelete ? _delete : null,
        ),
      ],
    );
  }
}

Future<void> showSettingsLogoutSheet(BuildContext context) async {
  final confirmed = await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.logout_rounded,
                  color: AppColors.green, size: 36),
              const SizedBox(height: 10),
              const Text(
                'Log out of Getin Coffee?',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'This local demo returns to Sign In and keeps your saved demo data.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB94A48),
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Log Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ) ??
      false;

  if (!confirmed || !context.mounted) {
    return;
  }
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const SignInScreen()),
    (_) => false,
  );
}

Future<bool> _showDemoVerification(
  BuildContext context, {
  required String title,
  required String destination,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(
            'Demo verification for $destination. In production an OTP/link must be verified before saving.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Verify Demo'),
            ),
          ],
        ),
      ) ??
      false;
}

class _SettingsPage extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsPage({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.viewPaddingOf(context).bottom + 28,
          ),
          children: children,
        ),
      ),
    );
  }
}

class _SwitchSection extends StatelessWidget {
  final String title;
  final List<String> labels;
  final CustomerSettingsStore store;

  const _SwitchSection({
    required this.title,
    required this.labels,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(labels.length, (index) {
              final label = labels[index];
              return Column(
                children: [
                  SwitchListTile.adaptive(
                    title: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    value: store.notifications[label] ?? true,
                    onChanged: (value) => store.setNotification(label, value),
                  ),
                  if (index != labels.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final bool danger;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB94A48) : AppColors.green;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFFCEDEC) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: danger ? const Color(0xFFE7B9B6) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(
                    color: danger ? const Color(0xFF8E3937) : AppColors.muted,
                    height: 1.4,
                    fontSize: 11,
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

class _SwitchCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile.adaptive(
        secondary: Icon(icon, color: AppColors.green),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.green,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _RadioCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RadioCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.beige.withOpacity(0.45) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.green : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool current;

  const _SessionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.current = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (current)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'CURRENT',
                style: TextStyle(
                  color: AppColors.beige,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.green,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.beige,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _DangerButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFB94A48),
          disabledBackgroundColor: const Color(0xFFE7B9B6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.green),
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
    ),
  );
}

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
