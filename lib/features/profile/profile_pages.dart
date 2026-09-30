import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth/customer_auth_store.dart';
import '../../core/customer/customer_country.dart';
import '../../core/customer/customer_personal_info_store.dart';
import '../../core/favorites/customer_favorites_store.dart';
import '../../core/navigation/app_navigation_controller.dart';
import '../../core/referrals/customer_referral_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/vouchers/customer_voucher_store.dart';
import '../../core/widgets/customer_avatar.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_screen.dart';
import '../product/product_detail_screen.dart';
import '../payments/payment_methods_screen.dart';
import '../gift_cards/gift_cards_screen.dart' as gift_cards_ui;
import '../auth/otp_screen.dart';
import '../auth/sign_in_screen.dart';
import 'profile_photo_actions.dart';
import 'settings_detail_screens.dart';

export '../addresses/saved_addresses_screen.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final birthday = TextEditingController();
  String _phoneCode = '';
  String _phoneFlag = '🌐';
  DateTime? _dateOfBirth;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _applyAccount();
  }

  void _applyAccount() {
    final account = CustomerAuthStore.instance.customer;
    if (account == null) return;
    final parts = account.name.trim().split(RegExp(r'\s+'));
    firstName.text = parts.isEmpty ? '' : parts.first;
    lastName.text = parts.length <= 1 ? '' : parts.sublist(1).join(' ');
    email.text = account.email;
    phone.text = account.phone;
    _dateOfBirth = account.dateOfBirth;
    birthday.text = _formatDate(account.dateOfBirth);
    final country = CustomerCountryCatalog.byIsoCode(account.countryCode);
    if (country != null) {
      _phoneFlag = country.flagEmoji;
      CustomerCountryStore.current.value = country;
    }
    final gender = _genderLabel(account.gender);
    if (CustomerPersonalInfoStore.genderOptions.contains(gender)) {
      CustomerPersonalInfoStore.gender.value = gender;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _genderLabel(String? value) {
    switch (value) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      default:
        return 'Prefer not to say';
    }
  }

  String _genderApiValue(String value) {
    switch (value) {
      case 'Male':
        return 'male';
      case 'Female':
        return 'female';
      default:
        return 'prefer_not_to_say';
    }
  }

  Future<void> _choosePhoneCountry() async {
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
          phone.clear();
        });
      },
    );
  }

  Future<void> _chooseBirthday() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _dateOfBirth = selected;
      birthday.text = _formatDate(selected);
    });
  }

  Future<void> _chooseGender() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final current = CustomerPersonalInfoStore.gender.value;
        final systemBottom = MediaQuery.viewPaddingOf(sheetContext).bottom;
        final bottomPadding = systemBottom > 20 ? systemBottom + 12 : 24.0;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Gender',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                ...CustomerPersonalInfoStore.genderOptions.map(
                  (option) => _ChoiceTile(
                    title: option,
                    selected: option == current,
                    onTap: () => Navigator.of(sheetContext).pop(option),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null) return;
    await CustomerPersonalInfoStore.setGender(selected);
  }

  Future<void> _chooseCountry() async {
    final selected = await showModalBottomSheet<CustomerCountry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (_) => _CountryPickerSheet(
        currentCountry: CustomerCountryStore.current.value,
      ),
    );
    if (selected == null || !mounted) return;
    await CustomerCountryStore.setCountry(selected);
    if (mounted) setState(() => _phoneFlag = selected.flagEmoji);
  }

  Future<void> _save() async {
    if (_saving) return;
    final first = firstName.text.trim();
    final last = lastName.text.trim();
    final normalizedEmail = email.text.trim().toLowerCase();
    final localPhone = phone.text.trim();
    final normalizedPhone = _phoneCode.isEmpty
        ? localPhone
        : '$_phoneCode $localPhone'.trim();
    if (first.isEmpty || normalizedEmail.isEmpty || normalizedPhone.isEmpty) {
      _snack(context, 'Name, email and phone number are required.');
      return;
    }
    final auth = CustomerAuthStore.instance;
    final previousPhone = auth.customer?.phone.trim();
    setState(() => _saving = true);
    try {
      final account = await auth.updateProfile(<String, dynamic>{
        'name': [first, if (last.isNotEmpty) last].join(' '),
        'email': normalizedEmail,
        'phone': normalizedPhone,
        'gender': _genderApiValue(CustomerPersonalInfoStore.gender.value),
        'date_of_birth': _dateOfBirth == null ? null : _formatDate(_dateOfBirth),
        'country_code': CustomerCountryStore.current.value.normalizedIsoCode,
      });
      await CustomerPersonalInfoStore.setGender(_genderLabel(account.gender));
      final country = CustomerCountryCatalog.byIsoCode(account.countryCode);
      if (country != null) await CustomerCountryStore.setCountry(country);
      if (!mounted) return;
      _applyAccount();
      _snack(context, 'Profile updated.');
      final phoneChanged = previousPhone != null &&
          previousPhone.isNotEmpty &&
          previousPhone != account.phone.trim();
      if (auth.usesApi && phoneChanged && !account.phoneVerified) {
        try {
          await auth.sendOtp();
          if (!mounted) return;
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                phoneNumber: account.phone,
                returnAfterVerification: true,
              ),
            ),
          );
        } catch (error) {
          if (mounted) _snack(context, auth.userMessage(error));
        }
      }
    } catch (error) {
      if (mounted) _snack(context, auth.userMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    phone.dispose();
    birthday.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = CustomerAuthStore.instance.customer;
    return _PageScaffold(
      title: 'Personal Information',
      body: Column(
        children: [
          const _ProfileAvatarEditor(),
          const SizedBox(height: 18),
          _LabeledField(label: 'First name', controller: firstName),
          _LabeledField(label: 'Last name', controller: lastName),
          _VerifiedField(
            label: account?.emailVerified == true ? 'Email · Verified' : 'Email',
            controller: email,
          ),
          _VerifiedPhoneField(
            label: account?.phoneVerified == true
                ? 'Phone number · Verified'
                : 'Phone number',
            controller: phone,
            flag: _phoneFlag,
            code: _phoneCode,
            onCountryTap: _choosePhoneCountry,
          ),
          _LabeledField(
            label: 'Date of birth',
            controller: birthday,
            readOnly: true,
            onTap: _chooseBirthday,
          ),
          ValueListenableBuilder<String>(
            valueListenable: CustomerPersonalInfoStore.gender,
            builder: (context, gender, _) => _PickerRow(
              icon: Icons.person_outline_rounded,
              label: 'Gender',
              value: gender,
              onTap: _chooseGender,
            ),
          ),
          ValueListenableBuilder<CustomerCountry>(
            valueListenable: CustomerCountryStore.current,
            builder: (context, country, _) => _PickerRow(
              icon: Icons.public_rounded,
              label: 'Country',
              value: '${country.flagEmoji} ${country.name}',
              onTap: _chooseCountry,
            ),
          ),
          const SizedBox(height: 18),
          _PrimaryButton(
            label: _saving ? 'Saving…' : 'Save Changes',
            onTap: _saving ? () {} : _save,
          ),
        ],
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final CustomerCountry currentCountry;

  const _CountryPickerSheet({required this.currentCountry});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CustomerCountry> get _countries {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return CustomerCountryCatalog.all;
    }
    return CustomerCountryCatalog.all.where((country) {
      return country.name.toLowerCase().contains(query) ||
          country.normalizedIsoCode.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.82;
    final countries = _countries;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'Choose Country',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _search,
              autofocus: false,
              onChanged: (value) => setState(() => _query = value),
              decoration: _inputDecoration('Search country or code').copyWith(
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.green,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(
            child: countries.isEmpty
                ? const Center(
                    child: Text(
                      'No countries found',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    itemCount: countries.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),
                    itemBuilder: (context, index) {
                      final country = countries[index];
                      final selected = country.normalizedIsoCode ==
                          widget.currentCountry.normalizedIsoCode;
                      return ListTile(
                        onTap: () => Navigator.of(context).pop(country),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        leading: Text(
                          country.flagEmoji,
                          style: const TextStyle(fontSize: 25),
                        ),
                        title: Text(
                          country.name,
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          country.normalizedIsoCode,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.green,
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon {
    if (title == 'Male') {
      return Icons.male_rounded;
    }
    if (title == 'Female') {
      return Icons.female_rounded;
    }
    return Icons.visibility_off_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? AppColors.beige.withOpacity(0.48) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? AppColors.green.withOpacity(0.42)
                    : AppColors.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.green : AppColors.cream,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _icon,
                    color: selected ? AppColors.beige : AppColors.green,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.green : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.green : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.beige,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PhoneEmailScreen extends StatelessWidget {
  const PhoneEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Phone & Email',
      body: Column(
        children: [
          _ActionCard(
            icon: Icons.phone_iphone_rounded,
            title: '+20 10 0000 0000',
            subtitle: 'Verified phone number',
            trailing: 'Change',
            onTap: () => _snack(
              context,
              'Phone changes should use OTP verification.',
            ),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.email_outlined,
            title: 'mohammed@example.com',
            subtitle: 'Verified email address',
            trailing: 'Change',
            onTap: () => _snack(
              context,
              'Email changes should require verification.',
            ),
          ),
          const SizedBox(height: 14),
          const _InfoNote(
            text:
                'Changing your phone or email should not become active until the new contact method is verified.',
          ),
        ],
      ),
    );
  }
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaymentMethodsManagementScreen();
  }
}

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Rewards',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RewardsHero(),
          const SizedBox(height: 18),
          const _SectionTitle('Available Rewards'),
          const SizedBox(height: 9),
          _RewardCard(
            icon: Icons.local_cafe_rounded,
            title: 'Free Drink',
            cost: '150 Stars',
            onTap: () => _snack(
              context,
              'Reward redemption will validate eligibility with Laravel.',
            ),
          ),
          const SizedBox(height: 8),
          _RewardCard(
            icon: Icons.upgrade_rounded,
            title: 'Free Size Upgrade',
            cost: '80 Stars',
            onTap: () => _snack(
              context,
              'Reward redemption will validate eligibility with Laravel.',
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Stars History'),
          const SizedBox(height: 9),
          const _HistoryCard(),
        ],
      ),
    );
  }
}

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  int index = 0;

  String _money(double value) {
    final whole = value == value.roundToDouble();
    return whole
        ? 'EGP ${value.toStringAsFixed(0)}'
        : 'EGP ${value.toStringAsFixed(2)}';
  }

  String _date(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  List<CustomerVoucher> _vouchersForTab(CustomerVoucherStore store) {
    switch (index) {
      case 0:
        return store.availableVouchers;
      case 1:
        return store.appliedVouchers;
      case 2:
        return store.usedVouchers;
      case 3:
        return store.expiredVouchers;
      default:
        return const <CustomerVoucher>[];
    }
  }

  Future<void> _useVoucher(CustomerVoucher voucher) async {
    final cart = CartController.instance;

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${voucher.code} is ready. Add eligible items first, then apply it in Cart.',
          ),
        ),
      );
      AppNavigationController.instance.openMenu();
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final result = cart.applyVoucher(voucher.id);
    late final String message;

    switch (result) {
      case VoucherApplyResult.success:
        message =
            '${voucher.code} applied · Save ${_money(cart.voucherDiscount)}';
      case VoucherApplyResult.minimumSpendNotMet:
        message = cart.voucherIneligibilityReason(voucher);
      case VoucherApplyResult.expired:
        message = 'This voucher has expired and cannot be applied.';
      case VoucherApplyResult.used:
        message = 'This voucher has already been used.';
      case VoucherApplyResult.emptyCart:
        message = 'Add eligible items before applying this voucher.';
      case VoucherApplyResult.notFound:
        message = 'Voucher not found.';
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CartScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CustomerVoucherStore.instance,
      builder: (context, _) {
        final store = CustomerVoucherStore.instance;
        final vouchers = _vouchersForTab(store);

        return _PageScaffold(
          title: 'Vouchers',
          body: Column(
            children: [
              _SegmentedTabs(
                labels: const ['Available', 'Applied', 'Used', 'Expired'],
                selected: index,
                onChanged: (value) => setState(() => index = value),
              ),
              const SizedBox(height: 14),
              if (vouchers.isEmpty)
                _EmptyState(
                  icon: index == 3
                      ? Icons.history_rounded
                      : Icons.confirmation_number_outlined,
                  title: switch (index) {
                    0 => 'No available vouchers',
                    1 => 'No applied voucher',
                    2 => 'No used vouchers yet',
                    _ => 'No expired vouchers',
                  },
                  subtitle: 'Voucher status and history will appear here.',
                )
              else
                ...List.generate(
                  vouchers.length,
                  (voucherIndex) {
                    final voucher = vouchers[voucherIndex];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: voucherIndex == vouchers.length - 1 ? 0 : 10,
                      ),
                      child: _VoucherCard(
                        title: voucher.title,
                        description: voucher.description,
                        code: voucher.code,
                        discount: _money(voucher.discountAmount),
                        minimumSpend: _money(voucher.minimumSpend),
                        expiry: _date(voucher.expiresAt),
                        terms: voucher.terms,
                        status: voucher.status,
                        usedAt: voucher.usedAt == null
                            ? null
                            : _date(voucher.usedAt!),
                        onUseNow: voucher.status == VoucherStatus.available
                            ? () => _useVoucher(voucher)
                            : null,
                        onViewCart: voucher.status == VoucherStatus.applied
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CartScreen(),
                                  ),
                                )
                            : null,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E8D4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Demo only · Voucher eligibility is stored locally for now. Laravel will later validate customer, branch, product and campaign rules.',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 9.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int index = 0;

  void _openProduct(BuildContext context, FavoriteProductEntry product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          name: product.name,
          description: product.description,
          image: product.image,
          price: product.price,
          branchName: product.branchName,
          serviceType: product.serviceType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Favorites',
      body: Column(
        children: [
          _SegmentedTabs(
            labels: const ['Products', 'Branches'],
            selected: index,
            onChanged: (value) => setState(() => index = value),
          ),
          const SizedBox(height: 14),
          if (index == 0)
            AnimatedBuilder(
              animation: CustomerFavoritesStore.instance,
              builder: (context, _) {
                final products = CustomerFavoritesStore.instance.products;
                if (products.isEmpty) {
                  return const _FavoritesEmptyState();
                }

                return Column(
                  children: [
                    for (var i = 0; i < products.length; i++) ...[
                      _FavoriteProduct(
                        product: products[i],
                        onTap: () => _openProduct(context, products[i]),
                        onRemove: () => CustomerFavoritesStore.instance
                            .removeById(products[i].id),
                      ),
                      if (i != products.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            )
          else ...[
            const _FavoriteBranch(
              name: 'Getin Stanley',
              detail: '0.4 km · Open now',
            ),
            const SizedBox(height: 10),
            const _FavoriteBranch(
              name: 'Getin San Stefano',
              detail: '3.1 km · Open now',
            ),
            const SizedBox(height: 10),
            const _InfoNote(
              text:
                  'Branch favorites remain demo content for now. Product favorites are fully shared across Home, Menu and Product Detail.',
            ),
          ],
        ],
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            color: AppColors.green,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            'No favorite products yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tap the heart on a product to save it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class ReferFriendScreen extends StatelessWidget {
  const ReferFriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final referral = CustomerReferralStore.instance;

    return _PageScaffold(
      title: 'Refer a Friend',
      body: AnimatedBuilder(
        animation: referral,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.group_add_outlined,
                      color: AppColors.gold,
                      size: 42,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Give EGP 50. Get EGP 50.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.beige,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Invite a friend with your personal link or code. Your reward becomes available after their eligible first order is completed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ReferralCode(referral: referral),
              const SizedBox(height: 14),
              _ReferralLinkCard(referral: referral),
              const SizedBox(height: 14),
              _MiniStats(
                values: [
                  '${referral.invitedCount}',
                  '${referral.completedCount}',
                  'EGP ${referral.totalEarned.toStringAsFixed(0)}',
                ],
                labels: const ['Invited', 'Completed', 'Earned'],
              ),
              const SizedBox(height: 20),
              const _SectionTitle('How It Works'),
              const SizedBox(height: 10),
              const _ReferralHowItWorks(),
              const SizedBox(height: 20),
              const _SectionTitle('Referral Activity'),
              const SizedBox(height: 10),
              ...referral.history.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReferralActivityCard(item: item),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Demo activity is stored locally for this prototype. Final referral eligibility and rewards will be verified by the backend.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 9.5,
                  height: 1.4,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class GiftCardsScreen extends StatelessWidget {
  const GiftCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const gift_cards_ui.GiftCardsScreen();
  }
}

class BirthdayRewardScreen extends StatelessWidget {
  const BirthdayRewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Birthday Reward',
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.cake_rounded,
                  color: AppColors.gold,
                  size: 44,
                ),
                SizedBox(height: 12),
                Text(
                  '4 February',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your birthday reward will appear here when your account is eligible.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _InfoNote(
            text:
                'When active, the reward should show its exact validity dates and eligible products.',
          ),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsHelpSupportScreen();
  }
}

class AboutGetinScreen extends StatelessWidget {
  const AboutGetinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'About Getin',
      body: Column(
        children: [
          const _BrandBlock(),
          const SizedBox(height: 16),
          ...[
            'Our Story',
            'Our Coffee',
            'Locations',
            'Careers',
            'Contact Us',
            'Terms & Conditions',
            'Privacy Policy',
            'Membership Terms',
            'Rewards Terms',
          ].map(
            (label) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SimpleNavRow(label: label),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'App Version 1.0.0 (1)',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  final Map<String, bool> values = {
    'Order status': true,
    'Driver updates': true,
    'Stars & rewards': true,
    'Voucher expiry': true,
    'Offers & promotions': true,
    'New products': true,
    'Member-only offers': true,
    'Security alerts': true,
    'Payment alerts': true,
  };

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Notifications',
      body: Column(
        children: [
          _ToggleGroup(
            title: 'Order Updates',
            labels: const [
              'Order status',
              'Driver updates',
            ],
            values: values,
            onChanged: _change,
          ),
          const SizedBox(height: 14),
          _ToggleGroup(
            title: 'Rewards',
            labels: const [
              'Stars & rewards',
              'Voucher expiry',
            ],
            values: values,
            onChanged: _change,
          ),
          const SizedBox(height: 14),
          _ToggleGroup(
            title: 'Offers',
            labels: const [
              'Offers & promotions',
              'New products',
              'Member-only offers',
            ],
            values: values,
            onChanged: _change,
          ),
          const SizedBox(height: 14),
          _ToggleGroup(
            title: 'Account',
            labels: const [
              'Security alerts',
              'Payment alerts',
            ],
            values: values,
            onChanged: _change,
          ),
          const SizedBox(height: 14),
          const _InfoNote(
            text:
                'Order, payment and security messages should remain service notifications and should not be mixed with marketing preferences.',
          ),
        ],
      ),
    );
  }

  void _change(String key, bool value) {
    setState(() => values[key] = value);
  }
}

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String selected = 'English';

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Language',
      body: _RadioList(
        values: const ['English', 'العربية'],
        selected: selected,
        onChanged: (value) => setState(() => selected = value),
      ),
    );
  }
}

class CountryRegionScreen extends StatefulWidget {
  const CountryRegionScreen({super.key});

  @override
  State<CountryRegionScreen> createState() => _CountryRegionScreenState();
}

class _CountryRegionScreenState extends State<CountryRegionScreen> {
  String selected = 'Egypt';

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Country / Region',
      body: Column(
        children: [
          _RadioList(
            values: const [
              'Egypt',
              'Saudi Arabia',
              'United Arab Emirates',
            ],
            selected: selected,
            onChanged: (value) {
              setState(() => selected = value);
              _snack(
                context,
                'Changing country should clear or revalidate the cart because pricing and availability can change.',
              );
            },
          ),
          const SizedBox(height: 14),
          const _InfoNote(
            text:
                'Country should control currency, branches, menu, prices, payments, taxes, membership and delivery rules from backend configuration.',
          ),
        ],
      ),
    );
  }
}

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  String selected = 'System Default';

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Appearance',
      body: Column(
        children: [
          _RadioList(
            values: const [
              'System Default',
              'Light',
              'Dark',
            ],
            selected: selected,
            onChanged: (value) => setState(() => selected = value),
          ),
          const SizedBox(height: 14),
          const _InfoNote(
            text:
                'Dark mode should only be enabled for production after every Getin screen has a complete dark theme.',
          ),
        ],
      ),
    );
  }
}

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool biometrics = false;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Password & Security',
      body: Column(
        children: [
          _ActionCard(
            icon: Icons.password_rounded,
            title: 'Change Password',
            onTap: () => _snack(
              context,
              'Password reset will connect to authentication API.',
            ),
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.phone_iphone_rounded,
            title: 'Phone',
            subtitle: 'Verified',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PhoneNumberSettingsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'Verified',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EmailSettingsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SwitchCard(
            icon: Icons.fingerprint_rounded,
            title: 'Biometric Login',
            subtitle: 'Face ID / Fingerprint',
            value: biometrics,
            onChanged: (value) => setState(() => biometrics = value),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Active Sessions'),
          const SizedBox(height: 9),
          const _SessionCard(
            title: 'Samsung Galaxy',
            subtitle: 'Current device',
            current: true,
          ),
          const SizedBox(height: 8),
          const _SessionCard(
            title: 'Chrome on Mac',
            subtitle: 'Last active 2 hours ago',
            current: false,
          ),
          const SizedBox(height: 14),
          _DangerButton(
            label: 'Sign Out From All Devices',
            onTap: () => _snack(
              context,
              'This should revoke all other auth sessions.',
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool recommendations = true;
  bool marketing = true;
  bool analytics = true;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Privacy',
      body: Column(
        children: [
          const _ActionCard(
            icon: Icons.location_on_outlined,
            title: 'Location',
            subtitle: 'Used to find nearby branches and delivery availability',
          ),
          const SizedBox(height: 8),
          _SwitchCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Personalized Recommendations',
            value: recommendations,
            onChanged: (value) => setState(() => recommendations = value),
          ),
          const SizedBox(height: 8),
          _SwitchCard(
            icon: Icons.campaign_outlined,
            title: 'Marketing Personalization',
            value: marketing,
            onChanged: (value) => setState(() => marketing = value),
          ),
          const SizedBox(height: 8),
          _SwitchCard(
            icon: Icons.analytics_outlined,
            title: 'Analytics',
            value: analytics,
            onChanged: (value) => setState(() => analytics = value),
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.download_outlined,
            title: 'Download My Data',
            onTap: () => _snack(
              context,
              'Data export request will connect to backend.',
            ),
          ),
          const SizedBox(height: 8),
          const _ActionCard(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
          ),
        ],
      ),
    );
  }
}

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Delete Account',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFCEDEC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE7B9B6),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFB94A48),
                  size: 30,
                ),
                SizedBox(height: 10),
                Text(
                  'Deleting your account will remove:',
                  style: TextStyle(
                    color: Color(0xFF8E3937),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• profile information\n'
                  '• saved addresses\n'
                  '• favorites\n'
                  '• stored payment references\n\n'
                  'Some transaction records may be retained where legally required.',
                  style: TextStyle(
                    color: Color(0xFF8E3937),
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DangerButton(
            label: 'Continue to Delete Account',
            onTap: () => _snack(
              context,
              'Production flow: OTP verification → final confirmation → backend deletion request.',
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showLogoutSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: AppColors.green,
              size: 34,
            ),
            const SizedBox(height: 12),
            const Text(
              'Log out of Getin Coffee?',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'You can sign back in anytime.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await CustomerAuthStore.instance.logoutCurrent();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                        (_) => false,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB94A48),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Log Out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PageScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const _PageScaffold({
    required this.title,
    required this.body,
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
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.viewPaddingOf(context).bottom + 28,
          ),
          child: body,
        ),
      ),
    );
  }
}

class _ProfileAvatarEditor extends StatelessWidget {
  const _ProfileAvatarEditor();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomerAvatar(
        size: 88,
        showCameraBadge: true,
        onTap: () => showProfilePhotoActions(context),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final VoidCallback? onTap;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: _inputDecoration(label),
      ),
    );
  }
}

class _VerifiedField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _VerifiedField({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextField(
        controller: controller,
        decoration: _inputDecoration(label).copyWith(
          suffixIcon: const Icon(
            Icons.verified_rounded,
            color: AppColors.green,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _VerifiedPhoneField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String flag;
  final String code;
  final VoidCallback onCountryTap;

  const _VerifiedPhoneField({
    required this.label,
    required this.controller,
    required this.flag,
    required this.code,
    required this.onCountryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.phone,
        decoration: _inputDecoration(label).copyWith(
          prefixIconConstraints: const BoxConstraints(minWidth: 96),
          prefixIcon: InkWell(
            onTap: onCountryTap,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    code,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.muted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          suffixIcon: const Icon(
            Icons.verified_rounded,
            color: AppColors.green,
            size: 19,
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: AppColors.muted,
      fontSize: 11,
    ),
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(
        color: AppColors.border,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(
        color: AppColors.green,
        width: 1.3,
      ),
    ),
  );
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: _ActionCard(
        icon: icon,
        title: label,
        subtitle: value,
        trailing: 'Change',
        onTap: onTap,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(13, 7, 7, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.green),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 8.5,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _RewardsHero extends StatelessWidget {
  const _RewardsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR STARS',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '120',
            style: TextStyle(
              color: AppColors.beige,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '30 Stars until your next reward',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          SizedBox(height: 11),
          LinearProgressIndicator(
            value: 120 / 150,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.gold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            '120 / 150',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 8.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String cost;
  final VoidCallback onTap;

  const _RewardCard({
    required this.icon,
    required this.title,
    required this.cost,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: icon,
      title: title,
      subtitle: cost,
      trailing: 'Redeem',
      onTap: onTap,
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('+18', 'Order #10583'),
      ('+10', 'Bonus Stars promotion'),
      ('-150', 'Free Drink redeemed'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: List.generate(
          rows.length,
          (index) => Column(
            children: [
              ListTile(
                dense: true,
                title: Text(
                  rows[index].$2,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Text(
                  rows[index].$1,
                  style: TextStyle(
                    color: rows[index].$1.startsWith('+')
                        ? AppColors.green
                        : const Color(0xFFB94A48),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (index != rows.length - 1)
                const Divider(
                  height: 1,
                  color: AppColors.border,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final String title;
  final String description;
  final String code;
  final String discount;
  final String minimumSpend;
  final String expiry;
  final String terms;
  final VoucherStatus status;
  final String? usedAt;
  final VoidCallback? onUseNow;
  final VoidCallback? onViewCart;

  const _VoucherCard({
    required this.title,
    required this.description,
    required this.code,
    required this.discount,
    required this.minimumSpend,
    required this.expiry,
    required this.terms,
    required this.status,
    required this.usedAt,
    required this.onUseNow,
    required this.onViewCart,
  });

  String get statusLabel => switch (status) {
        VoucherStatus.available => 'AVAILABLE',
        VoucherStatus.applied => 'APPLIED',
        VoucherStatus.used => 'USED',
        VoucherStatus.expired => 'EXPIRED',
      };

  @override
  Widget build(BuildContext context) {
    final disabled =
        status == VoucherStatus.used || status == VoucherStatus.expired;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status == VoucherStatus.applied
              ? AppColors.green
              : AppColors.border,
          width: status == VoucherStatus.applied ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: disabled ? AppColors.muted : AppColors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: status == VoucherStatus.applied
                      ? const Color(0xFFF0E8D4)
                      : AppColors.cream,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: disabled ? AppColors.muted : AppColors.green,
                    fontSize: 7.8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _VoucherDetailRow(label: 'Code', value: code, strong: true),
                _VoucherDetailRow(label: 'Discount', value: discount),
                _VoucherDetailRow(
                  label: 'Minimum spend',
                  value: minimumSpend,
                ),
                _VoucherDetailRow(label: 'Expiry', value: expiry),
                if (usedAt != null)
                  _VoucherDetailRow(label: 'Used', value: usedAt!),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            terms,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8.8,
              height: 1.4,
            ),
          ),
          if (onUseNow != null || onViewCart != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onUseNow ?? onViewCart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.beige,
                  minimumSize: const Size.fromHeight(44),
                ),
                child: Text(onUseNow != null ? 'Use Now' : 'View in Cart'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoucherDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _VoucherDetailRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 8.8,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: strong ? AppColors.gold : AppColors.green,
              fontSize: 9,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteProduct extends StatelessWidget {
  final FavoriteProductEntry product;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteProduct({
    required this.product,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  product.image,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.beige.withOpacity(0.4),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.local_cafe_rounded,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Saved from ${product.branchName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 8.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.price,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove favorite',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteBranch extends StatelessWidget {
  final String name;
  final String detail;

  const _FavoriteBranch({
    required this.name,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.storefront_rounded,
      title: name,
      subtitle: detail,
      trailing: 'View',
      onTap: () {
        Navigator.of(context).pop();
        AppNavigationController.instance.openMenu();
      },
    );
  }
}

class _ReferralCode extends StatelessWidget {
  final CustomerReferralStore referral;

  const _ReferralCode({required this.referral});

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: referral.referralCode));
    _snack(context, 'Referral code copied.');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'YOUR REFERRAL CODE',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 5),
          SelectableText(
            referral.referralCode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyCode(context),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy Code'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Share.share(
                    referral.shareMessage,
                    subject: 'Getin Coffee referral',
                  ),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.beige,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferralLinkCard extends StatelessWidget {
  final CustomerReferralStore referral;

  const _ReferralLinkCard({required this.referral});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REFERRAL LINK',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  referral.referralLink,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Copy referral link',
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: referral.referralLink),
                  );
                  _snack(context, 'Referral link copied.');
                },
                icon: const Icon(Icons.link_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferralHowItWorks extends StatelessWidget {
  const _ReferralHowItWorks();

  @override
  Widget build(BuildContext context) {
    const steps = <(IconData, String, String)>[
      (
        Icons.ios_share_rounded,
        '1. Share your invite',
        'Send your personal referral link or code to a friend.',
      ),
      (
        Icons.person_add_alt_1_rounded,
        '2. Friend registers',
        'Your friend creates a new Getin account using your link or code.',
      ),
      (
        Icons.shopping_bag_outlined,
        '3. First eligible order',
        'Your friend completes the first order that qualifies under the referral rules.',
      ),
      (
        Icons.card_giftcard_rounded,
        '4. Reward becomes available',
        'After eligibility is confirmed, the referral reward becomes available to use.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(step.$1, color: AppColors.green, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.$2,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.$3,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 9.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (index != steps.length - 1)
                const Divider(height: 1, color: AppColors.border),
            ],
          );
        }),
      ),
    );
  }
}

class _ReferralActivityCard extends StatelessWidget {
  final CustomerReferralActivity item;

  const _ReferralActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final earned = item.rewardEarned > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              earned
                  ? Icons.card_giftcard_rounded
                  : Icons.person_outline_rounded,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.friendName,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.status.label} · ${item.dateLabel}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color:
                  earned ? AppColors.green.withOpacity(0.10) : AppColors.cream,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              earned
                  ? '+ EGP ${item.rewardEarned.toStringAsFixed(0)}'
                  : item.status.shortLabel,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStats extends StatelessWidget {
  final List<String> values;
  final List<String> labels;

  const _MiniStats({
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        values.length,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index == values.length - 1 ? 0 : 7,
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 13,
              horizontal: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Column(
              children: [
                Text(
                  values[index],
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  labels[index],
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/getin_logo_mark.png',
          height: 72,
        ),
        const SizedBox(height: 10),
        const Text(
          'Getin Coffee',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Good coffee. Good days.',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _SimpleNavRow extends StatelessWidget {
  final String label;

  const _SimpleNavRow({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.chevron_right_rounded,
      title: label,
      onTap: () => _snack(
        context,
        '$label content will connect to CMS/backend.',
      ),
    );
  }
}

class _ToggleGroup extends StatelessWidget {
  final String title;
  final List<String> labels;
  final Map<String, bool> values;
  final void Function(String, bool) onChanged;

  const _ToggleGroup({
    required this.title,
    required this.labels,
    required this.values,
    required this.onChanged,
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
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            children: List.generate(
              labels.length,
              (index) => Column(
                children: [
                  SwitchListTile(
                    dense: true,
                    title: Text(
                      labels[index],
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: values[labels[index]] ?? false,
                    activeColor: AppColors.green,
                    onChanged: (value) => onChanged(labels[index], value),
                  ),
                  if (index != labels.length - 1)
                    const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RadioList extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _RadioList({
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: List.generate(
          values.length,
          (index) => Column(
            children: [
              RadioListTile<String>(
                value: values[index],
                groupValue: selected,
                activeColor: AppColors.green,
                title: Text(
                  values[index],
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
              if (index != values.length - 1)
                const Divider(
                  height: 1,
                  color: AppColors.border,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool current;

  const _SessionCard({
    required this.title,
    required this.subtitle,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.devices_rounded,
      title: title,
      subtitle: subtitle,
      trailing: current ? 'Current' : 'Log Out',
      onTap: current ? null : () {},
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
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String text;

  const _InfoNote({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.beige.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.green,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 9,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.check_rounded),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.beige,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFB94A48),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: List.generate(
          labels.length,
          (index) => Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      selected == index ? AppColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color:
                        selected == index ? AppColors.beige : AppColors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 40,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.green,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
