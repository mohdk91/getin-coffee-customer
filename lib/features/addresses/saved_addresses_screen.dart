import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/addresses/customer_address_store.dart';
import '../../core/theme/app_colors.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  Future<void> _openEditor(
    BuildContext context, {
    CustomerAddress? address,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddressEditorScreen(address: address),
      ),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    CustomerAddress address,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottom = MediaQuery.viewPaddingOf(sheetContext).bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(18, 12, 18, bottom + 18),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.68),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${address.labelUpper} · ${address.title}',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _SheetAction(
                icon: Icons.edit_outlined,
                title: 'Edit address',
                onTap: () => Navigator.pop(sheetContext, 'edit'),
              ),
              if (!address.isDefault)
                _SheetAction(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Make default',
                  onTap: () => Navigator.pop(sheetContext, 'default'),
                ),
              _SheetAction(
                icon: Icons.delete_outline_rounded,
                title: 'Delete address',
                destructive: true,
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    if (action == 'edit') {
      await _openEditor(context, address: address);
      return;
    }

    if (action == 'default') {
      await CustomerAddressStore.instance.setDefault(address.id);
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete this address?'),
          content: Text(
            '${address.labelUpper} · ${address.title} will be removed from this local demo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await CustomerAddressStore.instance.deleteAddress(address.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = CustomerAddressStore.instance;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PageHeader(
              title: 'Saved Addresses',
              onBack: () => Navigator.pop(context),
              trailing: IconButton(
                onPressed: () => _openEditor(context),
                icon: const Icon(
                  Icons.add_rounded,
                  color: AppColors.green,
                  size: 30,
                ),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: store,
                builder: (context, _) {
                  final addresses = store.addresses;
                  if (addresses.isEmpty) {
                    return _EmptyAddresses(
                      onAdd: () => _openEditor(context),
                    );
                  }
                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      MediaQuery.paddingOf(context).bottom + 28,
                    ),
                    itemCount: addresses.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == addresses.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _PrimaryButton(
                            label: 'Add New Address',
                            icon: Icons.add_location_alt_outlined,
                            onTap: () => _openEditor(context),
                          ),
                        );
                      }
                      final address = addresses[index];
                      return _AddressCard(
                        address: address,
                        onEdit: () => _openEditor(context, address: address),
                        onMore: () => _showActions(context, address),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddressEditorScreen extends StatefulWidget {
  final CustomerAddress? address;

  const AddressEditorScreen({super.key, this.address});

  @override
  State<AddressEditorScreen> createState() => _AddressEditorScreenState();
}

class _AddressEditorScreenState extends State<AddressEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _area;
  late final TextEditingController _city;
  late final TextEditingController _building;
  late final TextEditingController _floor;
  late final TextEditingController _apartment;
  late final TextEditingController _instructions;

  late String _label;
  late bool _makeDefault;
  late LatLng _pin;
  bool _saving = false;

  bool get _editing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _label = address?.label ?? 'Home';
    _makeDefault = address?.isDefault ?? false;
    _area = TextEditingController(text: address?.area ?? 'Stanley');
    _city = TextEditingController(text: address?.city ?? 'Alexandria');
    _building = TextEditingController(text: address?.building ?? '');
    _floor = TextEditingController(text: address?.floor ?? '');
    _apartment = TextEditingController(text: address?.apartment ?? '');
    _instructions = TextEditingController(
      text: address?.deliveryInstructions ?? '',
    );
    _pin = LatLng(
      address?.latitude ?? 31.23945,
      address?.longitude ?? 29.96524,
    );
  }

  @override
  void dispose() {
    _area.dispose();
    _city.dispose();
    _building.dispose();
    _floor.dispose();
    _apartment.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) {
      return;
    }
    setState(() => _saving = true);

    final address = CustomerAddress(
      id: widget.address?.id ?? '',
      label: _label,
      area: _area.text.trim(),
      city: _city.text.trim(),
      building: _building.text.trim(),
      floor: _floor.text.trim(),
      apartment: _apartment.text.trim(),
      deliveryInstructions: _instructions.text.trim(),
      latitude: _pin.latitude,
      longitude: _pin.longitude,
      isDefault: _makeDefault,
    );

    if (_editing) {
      await CustomerAddressStore.instance.updateAddress(address);
    } else {
      await CustomerAddressStore.instance.addAddress(address);
    }

    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PageHeader(
              title: _editing ? 'Edit Address' : 'Add Address',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.paddingOf(context).bottom + 28,
                  ),
                  children: [
                    const _StepLabel(number: '1', text: 'Choose location'),
                    const SizedBox(height: 10),
                    _MapPicker(
                      pin: _pin,
                      onChanged: (pin) => setState(() => _pin = pin),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap anywhere on the map to move the demo delivery pin.',
                      style: TextStyle(
                        color: AppColors.muted.withOpacity(0.95),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _StepLabel(number: '2', text: 'Address details'),
                    const SizedBox(height: 12),
                    _LabelSelector(
                      value: _label,
                      onChanged: (value) => setState(() => _label = value),
                    ),
                    const SizedBox(height: 12),
                    _AddressField(
                      controller: _area,
                      label: 'Area',
                      hint: 'Stanley',
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    _AddressField(
                      controller: _city,
                      label: 'City',
                      hint: 'Alexandria',
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    _AddressField(
                      controller: _building,
                      label: 'Building',
                      hint: '12',
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _AddressField(
                            controller: _floor,
                            label: 'Floor',
                            hint: '4',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AddressField(
                            controller: _apartment,
                            label: 'Apartment',
                            hint: '8',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _AddressField(
                      controller: _instructions,
                      label: 'Delivery instructions',
                      hint: 'Call on arrival',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SwitchListTile(
                        value: _makeDefault,
                        activeColor: AppColors.green,
                        title: const Text(
                          'Make this my default address',
                          style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Checkout will use the default address automatically.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _makeDefault = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      label: _saving ? 'Saving…' : 'Save Address',
                      icon: Icons.check_rounded,
                      onTap: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<CustomerAddress?> showSavedAddressPicker(BuildContext context) async {
  final store = CustomerAddressStore.instance;
  return showModalBottomSheet<CustomerAddress>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final addresses = store.addresses;
          final selected = store.checkoutAddress;
          final bottom = MediaQuery.viewPaddingOf(context).bottom;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 18),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.68),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Delivery address',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Choose one of your saved addresses for this order.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: addresses.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No saved addresses yet.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: addresses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final address = addresses[index];
                            final isSelected = address.id == selected?.id;
                            return Material(
                              color: isSelected
                                  ? AppColors.beige.withOpacity(0.42)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () async {
                                  await store.selectForCheckout(address.id);
                                  if (context.mounted) {
                                    Navigator.pop(context, address);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.green
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.green
                                              : AppColors.cream,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          Icons.location_on_rounded,
                                          color: isSelected
                                              ? AppColors.beige
                                              : AppColors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${address.labelUpper} · ${address.title}',
                                              style: const TextStyle(
                                                color: AppColors.green,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              address.details,
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.green,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddressEditorScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add New Address'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: const BorderSide(color: AppColors.green),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _MapPicker extends StatelessWidget {
  final LatLng pin;
  final ValueChanged<LatLng> onChanged;

  const _MapPicker({required this.pin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 230,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: pin,
            initialZoom: 15,
            onTap: (_, point) => onChanged(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.getin.coffee',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pin,
                  width: 54,
                  height: 54,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.beige,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final CustomerAddress address;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: address.isDefault ? AppColors.green : AppColors.border,
          width: address.isDefault ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: address.isDefault ? AppColors.green : AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: address.isDefault ? AppColors.beige : AppColors.green,
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
                          '${address.labelUpper} · ${address.title}',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              color: AppColors.beige,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (address.details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address.details,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (address.deliveryInstructions.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      address.deliveryInstructions,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: onEdit,
                        child: const Text('Edit'),
                      ),
                      TextButton(
                        onPressed: onMore,
                        child: const Text('Manage'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyAddresses({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_location_alt_outlined,
              color: AppColors.green,
              size: 54,
            ),
            const SizedBox(height: 14),
            const Text(
              'No saved addresses yet',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a delivery address and it will also be available in Checkout.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            _PrimaryButton(
              label: 'Add New Address',
              icon: Icons.add_rounded,
              onTap: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  const _PageHeader({
    required this.title,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
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

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  const _SheetAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red.shade700 : AppColors.green;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: color),
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String number;
  final String text;

  const _StepLabel({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.beige,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LabelSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _LabelSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = <String>['Home', 'Work', 'Other'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        final selected = value == label;
        return ChoiceChip(
          selected: selected,
          label: Text(label),
          onSelected: (_) => onChanged(label),
          selectedColor: AppColors.green,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? AppColors.beige : AppColors.green,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(
            color: selected ? AppColors.green : AppColors.border,
          ),
        );
      }).toList(),
    );
  }
}

class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isRequired;
  final int maxLines;

  const _AddressField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isRequired = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: isRequired
          ? (value) => value == null || value.trim().isEmpty
              ? '$label is required'
              : null
          : null,
      style: const TextStyle(color: AppColors.green),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: TextStyle(color: AppColors.muted.withOpacity(0.65)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
    );
  }
}
