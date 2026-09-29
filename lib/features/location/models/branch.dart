class Branch {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final bool deliveryEnabled;
  final bool pickupEnabled;

  const Branch({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.deliveryEnabled,
    required this.pickupEnabled,
  });
}
