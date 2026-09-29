import '../../core/constants/app_images.dart';

class HomeCategoryMock {
  final String title;
  final String image;

  const HomeCategoryMock({
    required this.title,
    required this.image,
  });
}

class HomeProductMock {
  final String name;
  final String subtitle;
  final String price;
  final String image;

  const HomeProductMock({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.image,
  });
}

class HomeMockData {
  HomeMockData._();

  static const categories = <HomeCategoryMock>[
    HomeCategoryMock(title: 'Coffee', image: AppImages.categoryCoffee),
    HomeCategoryMock(title: 'Non-Coffee', image: AppImages.categoryNonCoffee),
    HomeCategoryMock(title: 'Food', image: AppImages.categoryFood),
    HomeCategoryMock(title: 'Bakery', image: AppImages.categoryBakery),
    HomeCategoryMock(
      title: 'Refreshments',
      image: AppImages.categoryRefreshments,
    ),
    HomeCategoryMock(
      title: 'Merchandise',
      image: AppImages.categoryMerchandise,
    ),
  ];

  static const bestSellers = <HomeProductMock>[
    HomeProductMock(
      name: 'Iced Latte',
      subtitle: 'Classic & bold',
      price: 'EGP 65',
      image: AppImages.icedLatte,
    ),
    HomeProductMock(
      name: 'Caramel Macchiato',
      subtitle: 'Rich & smooth',
      price: 'EGP 70',
      image: AppImages.caramelMacchiato,
    ),
    HomeProductMock(
      name: 'Pistachio Latte',
      subtitle: 'A nutty favorite',
      price: 'EGP 75',
      image: AppImages.pistachioLatte,
    ),
  ];

  static const recommended = <HomeProductMock>[
    HomeProductMock(
      name: 'Butter Croissant',
      subtitle: 'Freshly baked',
      price: 'EGP 45',
      image: AppImages.butterCroissant,
    ),
    HomeProductMock(
      name: 'Iced Americano',
      subtitle: 'Clean & refreshing',
      price: 'EGP 55',
      image: AppImages.icedAmericano,
    ),
    HomeProductMock(
      name: 'Blueberry Muffin',
      subtitle: 'Soft & fruity',
      price: 'EGP 60',
      image: AppImages.blueberryMuffin,
    ),
    HomeProductMock(
      name: 'Turkey & Cheese',
      subtitle: 'Quick savory bite',
      price: 'EGP 95',
      image: AppImages.turkeyCheeseSandwich,
    ),
  ];
}
