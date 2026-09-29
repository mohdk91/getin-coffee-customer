import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/reviews/customer_review_store.dart';

void main() {
  final store = CustomerReviewStore.instance;

  setUp(() {
    store.clearSubmittedReviews();
  });

  test('seeded product reviews provide average and distribution', () {
    final reviews = store.reviewsFor('Iced Latte');
    expect(reviews.length, 4);
    expect(store.averageRating('Iced Latte'), 4.75);
    expect(store.ratingDistribution('Iced Latte')[5], 3);
    expect(store.ratingDistribution('Iced Latte')[4], 1);
  });

  test('completed-order product review updates product review state', () {
    store.submitProductReview(
      orderId: 'GC-TEST',
      productName: 'Iced Latte',
      rating: 4,
      comment: 'Great demo drink.',
    );

    expect(
      store.hasProductReview(
        orderId: 'GC-TEST',
        productName: 'Iced Latte',
      ),
      isTrue,
    );
    expect(store.reviewsFor('Iced Latte').first.comment, 'Great demo drink.');
    expect(store.reviewsFor('Iced Latte').length, 5);
  });

  test('duplicate review for same order and product is ignored', () {
    store.submitProductReview(
      orderId: 'GC-TEST',
      productName: 'Blueberry Muffin',
      rating: 5,
      comment: 'First review',
    );
    store.submitProductReview(
      orderId: 'GC-TEST',
      productName: 'Blueberry Muffin',
      rating: 1,
      comment: 'Duplicate review',
    );

    final submitted = store.submittedReviewFor(
      orderId: 'GC-TEST',
      productName: 'Blueberry Muffin',
    );
    expect(submitted?.rating, 5);
    expect(submitted?.comment, 'First review');
  });

  test('driver rating is independent from product review', () {
    store.submitDriverReview(
      orderId: 'GC-DELIVERY',
      driverName: 'Omar Adel',
      rating: 5,
      comment: 'Friendly and on time.',
    );

    expect(store.hasDriverReview('GC-DELIVERY'), isTrue);
    expect(store.driverReviewFor('GC-DELIVERY')?.driverName, 'Omar Adel');
    expect(
      store.hasProductReview(
        orderId: 'GC-DELIVERY',
        productName: 'Iced Latte',
      ),
      isFalse,
    );
  });
}
