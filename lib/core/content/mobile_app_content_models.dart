class MobileContentMedia {
  final String type;
  final String url;
  final String? alt;

  const MobileContentMedia({required this.type, required this.url, this.alt});

  factory MobileContentMedia.fromJson(Map<String, dynamic> json) =>
      MobileContentMedia(
        type: json['type']?.toString() ?? 'image',
        url: json['url']?.toString() ?? '',
        alt: json['alt']?.toString(),
      );
}

class MobileContentDestination {
  final String type;
  final String? value;

  const MobileContentDestination({this.type = 'none', this.value});

  factory MobileContentDestination.fromJson(Map<String, dynamic> json) =>
      MobileContentDestination(
        type: json['type']?.toString() ?? 'none',
        value: json['value']?.toString(),
      );
}

class MobileContentItem {
  final int id;
  final String type;
  final String internalName;
  final String? title;
  final String? description;
  final int sortOrder;
  final MobileContentMedia? media;
  final MobileContentMedia? fallbackMedia;
  final MobileContentDestination destination;

  const MobileContentItem({
    required this.id,
    required this.type,
    required this.internalName,
    required this.sortOrder,
    required this.destination,
    this.title,
    this.description,
    this.media,
    this.fallbackMedia,
  });

  factory MobileContentItem.fromJson(Map<String, dynamic> json) {
    MobileContentMedia? parseMedia(Object? raw) => raw is Map
        ? MobileContentMedia.fromJson(Map<String, dynamic>.from(raw))
        : null;
    return MobileContentItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? '',
      internalName: json['internal_name']?.toString() ?? '',
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      media: parseMedia(json['media']),
      fallbackMedia: parseMedia(json['fallback_media']),
      destination: json['destination'] is Map
          ? MobileContentDestination.fromJson(
              Map<String, dynamic>.from(json['destination'] as Map),
            )
          : const MobileContentDestination(),
    );
  }
}

class MobileBannerContent {
  final int id;
  final String? title;
  final String? text;
  final String? imageUrl;
  final String? mobileImageUrl;
  final String? ctaLabel;
  final MobileContentDestination destination;
  final int sortOrder;

  const MobileBannerContent({
    required this.id,
    required this.destination,
    required this.sortOrder,
    this.title,
    this.text,
    this.imageUrl,
    this.mobileImageUrl,
    this.ctaLabel,
  });

  factory MobileBannerContent.fromJson(Map<String, dynamic> json) =>
      MobileBannerContent(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString(),
        text: json['text']?.toString(),
        imageUrl: json['image_url']?.toString(),
        mobileImageUrl: json['mobile_image_url']?.toString(),
        ctaLabel: json['cta_label']?.toString(),
        destination: json['destination'] is Map
            ? MobileContentDestination.fromJson(
                Map<String, dynamic>.from(json['destination'] as Map),
              )
            : const MobileContentDestination(),
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class MobileHomeSectionConfig {
  final int id;
  final String key;
  final String title;
  final String? subtitle;
  final String source;
  final int sortOrder;

  const MobileHomeSectionConfig({
    required this.id,
    required this.key,
    required this.title,
    required this.source,
    required this.sortOrder,
    this.subtitle,
  });

  factory MobileHomeSectionConfig.fromJson(Map<String, dynamic> json) =>
      MobileHomeSectionConfig(
        id: (json['id'] as num?)?.toInt() ?? 0,
        key: json['key']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString(),
        source: json['source']?.toString() ?? 'catalog',
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class MobileAppContentSnapshot {
  final MobileContentItem? splash;
  final List<MobileContentItem> onboarding;
  final List<MobileBannerContent> heroBanners;
  final List<MobileBannerContent> secondaryBanners;
  final List<MobileHomeSectionConfig> homeSections;

  const MobileAppContentSnapshot({
    this.splash,
    this.onboarding = const <MobileContentItem>[],
    this.heroBanners = const <MobileBannerContent>[],
    this.secondaryBanners = const <MobileBannerContent>[],
    this.homeSections = const <MobileHomeSectionConfig>[],
  });

  factory MobileAppContentSnapshot.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(Object? raw, T Function(Map<String, dynamic>) parse) =>
        (raw as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((row) => parse(Map<String, dynamic>.from(row)))
            .toList(growable: false);
    return MobileAppContentSnapshot(
      splash: json['splash'] is Map
          ? MobileContentItem.fromJson(
              Map<String, dynamic>.from(json['splash'] as Map),
            )
          : null,
      onboarding: parseList(json['onboarding'], MobileContentItem.fromJson),
      heroBanners: parseList(json['hero_banners'], MobileBannerContent.fromJson),
      secondaryBanners:
          parseList(json['secondary_banners'], MobileBannerContent.fromJson),
      homeSections:
          parseList(json['home_sections'], MobileHomeSectionConfig.fromJson),
    );
  }
}
