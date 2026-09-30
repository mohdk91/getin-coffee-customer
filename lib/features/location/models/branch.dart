class Branch {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final bool deliveryEnabled;
  final bool pickupEnabled;
  final String? phone;
  final String? address;
  final String? city;
  final String? imageUrl;
  final bool? isOpen;
  final String? statusLabel;

  const Branch({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.deliveryEnabled,
    required this.pickupEnabled,
    this.phone,
    this.address,
    this.city,
    this.imageUrl,
    this.isOpen,
    this.statusLabel,
  });
}
