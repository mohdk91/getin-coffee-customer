import 'package:flutter/material.dart';

import '../../core/reviews/customer_review_store.dart';
import '../../core/theme/app_colors.dart';

@immutable
class ReviewableProduct {
  final String name;
  final String description;
  final String image;
  final String price;

  const ReviewableProduct({
    required this.name,
    required this.description,
    required this.image,
    required this.price,
  });
}

class ProductReviewPreviewCard extends StatelessWidget {
  final String productName;

  const ProductReviewPreviewCard({
    super.key,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CustomerReviewStore.instance,
      builder: (context, _) {
        final store = CustomerReviewStore.instance;
        final reviews = store.reviewsFor(productName);
        final average = store.averageRating(productName);
        final preview = reviews.take(2).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Reviews',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductReviewsScreen(
                            productName: productName,
                          ),
                        ),
                      );
                    },
                    child: const Text('See All Reviews'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    average.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StaticStars(rating: average.round(), size: 17),
                  const SizedBox(width: 8),
                  Text(
                    '${reviews.length} reviews',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...preview.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == preview.length - 1 ? 0 : 10,
                        ),
                        child: _ReviewCard(review: entry.value),
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ProductReviewsScreen extends StatelessWidget {
  final String productName;

  const ProductReviewsScreen({
    super.key,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CustomerReviewStore.instance,
      builder: (context, _) {
        final store = CustomerReviewStore.instance;
        final reviews = store.reviewsFor(productName);
        final average = store.averageRating(productName);
        final distribution = store.ratingDistribution(productName);

        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            title: const Text('Reviews'),
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.green,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Text(
                productName,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _RatingSummaryCard(
                average: average,
                reviewCount: reviews.length,
                distribution: distribution,
              ),
              const SizedBox(height: 14),
              ...reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReviewCard(review: review),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class OrderReviewScreen extends StatelessWidget {
  final String orderId;
  final String branchName;
  final String fulfillment;
  final List<ReviewableProduct> products;
  final String? driverName;
  final String? employeeName;

  const OrderReviewScreen({
    super.key,
    required this.orderId,
    required this.branchName,
    required this.fulfillment,
    required this.products,
    this.driverName,
    this.employeeName,
  });

  bool _isCompleted(CustomerReviewStore store) {
    final productsDone = products.every(
      (product) => store.hasProductReview(
        orderId: orderId,
        productName: product.name,
      ),
    );
    final isDelivery = fulfillment == 'Delivery';
    final driverDone =
        !isDelivery || driverName == null || store.hasDriverReview(orderId);
    final employeeDone = isDelivery ||
        store.hasServiceReview(orderId: orderId, kind: 'employee');
    final branchDone =
        isDelivery || store.hasServiceReview(orderId: orderId, kind: 'branch');
    return productsDone && driverDone && employeeDone && branchDone;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CustomerReviewStore.instance,
      builder: (context, _) {
        final store = CustomerReviewStore.instance;
        final completed = _isCompleted(store);

        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            title: const Text('Rate your order'),
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.green,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMPLETED ORDER',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Order #$orderId',
                      style: const TextStyle(
                        color: AppColors.beige,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$branchName · $fulfillment',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    if (completed) ...[
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.beige,
                            size: 19,
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Thanks — this order has been fully reviewed.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Rate products',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Only products from completed orders are eligible in this demo.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              ...products.map(
                (product) {
                  final existing = store.submittedReviewFor(
                    orderId: orderId,
                    productName: product.name,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RateProductCard(
                      product: product,
                      existingReview: existing,
                      onRate: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReviewComposerScreen.product(
                              orderId: orderId,
                              productName: product.name,
                              image: product.image,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              if (driverName != null) ...[
                const SizedBox(height: 10),
                const Text(
                  'Rate delivery driver',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Driver rating is separate from product reviews.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                _RateDriverCard(
                  driverName: driverName!,
                  existingReview: store.driverReviewFor(orderId),
                  onRate: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReviewComposerScreen.driver(
                          orderId: orderId,
                          driverName: driverName!,
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (fulfillment == 'Pickup') ...[
                const SizedBox(height: 10),
                const Text(
                  'Rate pickup experience',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Employee/service and branch ratings are separate from product reviews.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                _RateServiceCard(
                  icon: Icons.badge_outlined,
                  title: employeeName ?? 'Getin Team',
                  subtitle: 'Pickup employee / service',
                  existingReview: store.serviceReviewFor(
                    orderId: orderId,
                    kind: 'employee',
                  ),
                  onRate: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReviewComposerScreen.employee(
                          orderId: orderId,
                          employeeName: employeeName ?? 'Getin Team',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _RateServiceCard(
                  icon: Icons.storefront_outlined,
                  title: branchName,
                  subtitle: 'Branch experience',
                  existingReview: store.serviceReviewFor(
                    orderId: orderId,
                    kind: 'branch',
                  ),
                  onRate: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReviewComposerScreen.branch(
                          orderId: orderId,
                          branchName: branchName,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ReviewComposerScreen extends StatefulWidget {
  final String orderId;
  final String? productName;
  final String? image;
  final String? driverName;
  final String? employeeName;
  final String? branchName;

  const ReviewComposerScreen.product({
    super.key,
    required this.orderId,
    required this.productName,
    required this.image,
  })  : driverName = null,
        employeeName = null,
        branchName = null;

  const ReviewComposerScreen.driver({
    super.key,
    required this.orderId,
    required this.driverName,
  })  : productName = null,
        image = null,
        employeeName = null,
        branchName = null;

  const ReviewComposerScreen.employee({
    super.key,
    required this.orderId,
    required this.employeeName,
  })  : productName = null,
        image = null,
        driverName = null,
        branchName = null;

  const ReviewComposerScreen.branch({
    super.key,
    required this.orderId,
    required this.branchName,
  })  : productName = null,
        image = null,
        driverName = null,
        employeeName = null;

  bool get isDriver => driverName != null;
  bool get isEmployee => employeeName != null;
  bool get isBranch => branchName != null;
  bool get isService => isDriver || isEmployee || isBranch;

  @override
  State<ReviewComposerScreen> createState() => _ReviewComposerScreenState();
}

class _ReviewComposerScreenState extends State<ReviewComposerScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  final Set<String> _quickTags = <String>{};
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a star rating first.')),
      );
      return;
    }
    if (_commentController.text.trim().isEmpty &&
        (!widget.isService || _quickTags.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isService
                ? 'Choose quick feedback or add a short comment.'
                : 'Add a short comment before submitting.',
          ),
        ),
      );
      return;
    }

    final store = CustomerReviewStore.instance;
    final alreadySubmitted = widget.isDriver
        ? store.hasDriverReview(widget.orderId)
        : widget.isEmployee
            ? store.hasServiceReview(orderId: widget.orderId, kind: 'employee')
            : widget.isBranch
                ? store.hasServiceReview(
                    orderId: widget.orderId, kind: 'branch')
                : store.hasProductReview(
                    orderId: widget.orderId,
                    productName: widget.productName!,
                  );
    if (alreadySubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This review was already submitted.')),
      );
      return;
    }

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) {
      return;
    }

    final typedComment = _commentController.text.trim();
    final quickComment = _quickTags.join(' · ');
    final combinedComment = [
      if (quickComment.isNotEmpty) quickComment,
      if (typedComment.isNotEmpty) typedComment,
    ].join(' — ');

    if (store.usesApi) {
      if (!widget.isDriver && !widget.isEmployee) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'GETIN does not expose this review type in the production API.',
            ),
          ),
        );
        return;
      }

      try {
        final submitted = await store.submitLiveReview(
          orderId: widget.orderId,
          rating: _rating,
          comment: combinedComment,
          driverName: widget.driverName,
          employeeName: widget.employeeName,
        );
        if (!mounted) {
          return;
        }
        setState(() => _submitting = false);
        if (!submitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'GETIN says this review is no longer eligible or was already submitted.',
              ),
            ),
          );
          return;
        }
        Navigator.of(context).pop();
      } catch (_) {
        if (!mounted) return;
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not submit this review to GETIN. Nothing was saved locally.',
            ),
          ),
        );
      }
      return;
    }

    if (widget.isDriver) {
      store.submitDriverReview(
        orderId: widget.orderId,
        driverName: widget.driverName!,
        rating: _rating,
        comment: combinedComment,
      );
    } else if (widget.isEmployee) {
      store.submitServiceReview(
        orderId: widget.orderId,
        kind: 'employee',
        subjectName: widget.employeeName!,
        rating: _rating,
        comment: combinedComment,
      );
    } else if (widget.isBranch) {
      store.submitServiceReview(
        orderId: widget.orderId,
        kind: 'branch',
        subjectName: widget.branchName!,
        rating: _rating,
        comment: combinedComment,
      );
    } else {
      store.submitProductReview(
        orderId: widget.orderId,
        productName: widget.productName!,
        rating: _rating,
        comment: typedComment,
      );
    }

    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isDriver
        ? 'Rate ${widget.driverName}'
        : widget.isEmployee
            ? 'Rate ${widget.employeeName}'
            : widget.isBranch
                ? 'Rate ${widget.branchName}'
                : widget.productName!;
    final quickOptions = widget.isDriver
        ? const <String>[
            'Fast delivery',
            'Friendly',
            'Careful handling',
            'Easy communication',
            'Late',
          ]
        : widget.isEmployee
            ? const <String>[
                'Friendly staff',
                'Fast service',
                'Helpful',
                'Order ready',
                'Professional',
              ]
            : widget.isBranch
                ? const <String>[
                    'Clean branch',
                    'Great atmosphere',
                    'Easy pickup',
                    'Well organized',
                    'Long wait',
                  ]
                : const <String>[];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          widget.isDriver
              ? 'Rate delivery'
              : widget.isEmployee
                  ? 'Rate employee'
                  : widget.isBranch
                      ? 'Rate branch'
                      : 'Rate product',
        ),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewPaddingOf(context).bottom + 28,
          ),
          children: [
            if (widget.image != null) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    widget.image!,
                    width: 130,
                    height: 130,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isDriver
                  ? 'How was your delivery experience?'
                  : widget.isEmployee
                      ? 'How was the pickup service from the Getin team?'
                      : widget.isBranch
                          ? 'How was your experience at this branch?'
                          : 'How was this product in order #${widget.orderId}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 20),
            _InteractiveStars(
              rating: _rating,
              onChanged: (rating) => setState(() => _rating = rating),
            ),
            if (quickOptions.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Quick feedback',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: quickOptions.map((tag) {
                    final selected = _quickTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          if (selected) {
                            _quickTags.remove(tag);
                          } else {
                            _quickTags.add(tag);
                          }
                        });
                      },
                      selectedColor: AppColors.beige,
                      checkmarkColor: AppColors.green,
                      side: const BorderSide(color: AppColors.border),
                    );
                  }).toList(growable: false),
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              minLines: 4,
              maxLines: 7,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Comment',
                hintText: widget.isDriver
                    ? 'Anything else about the delivery?'
                    : widget.isEmployee
                        ? 'Anything else about the employee/service?'
                        : widget.isBranch
                            ? 'Anything else about the branch?'
                            : 'Tell us what you liked or what could be better...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.white,
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
                  borderSide:
                      const BorderSide(color: AppColors.green, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.beige,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.beige,
                        ),
                      )
                    : const Icon(Icons.star_rounded),
                label: Text(
                  _submitting ? 'Submitting…' : 'Submit Review',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateProductCard extends StatelessWidget {
  final ReviewableProduct product;
  final CustomerProductReview? existingReview;
  final VoidCallback onRate;

  const _RateProductCard({
    required this.product,
    required this.existingReview,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final reviewed = existingReview != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              product.image,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reviewed ? 'Your review has been submitted.' : product.price,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                if (reviewed) ...[
                  const SizedBox(height: 5),
                  _StaticStars(rating: existingReview!.rating, size: 15),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (reviewed)
            const Icon(Icons.check_circle_rounded, color: AppColors.green)
          else
            OutlinedButton(
              onPressed: onRate,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
              ),
              child: const Text('Rate'),
            ),
        ],
      ),
    );
  }
}

class _RateDriverCard extends StatelessWidget {
  final String driverName;
  final CustomerDriverReview? existingReview;
  final VoidCallback onRate;

  const _RateDriverCard({
    required this.driverName,
    required this.existingReview,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final reviewed = existingReview != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.beige,
            child: Icon(Icons.delivery_dining_rounded, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reviewed ? 'Driver review submitted.' : 'Delivery driver',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                if (reviewed) ...[
                  const SizedBox(height: 5),
                  _StaticStars(rating: existingReview!.rating, size: 15),
                ],
              ],
            ),
          ),
          if (reviewed)
            const Icon(Icons.check_circle_rounded, color: AppColors.green)
          else
            OutlinedButton(
              onPressed: onRate,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
              ),
              child: const Text('Rate'),
            ),
        ],
      ),
    );
  }
}

class _RateServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final CustomerServiceReview? existingReview;
  final VoidCallback onRate;

  const _RateServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.existingReview,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final reviewed = existingReview != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.beige,
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
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reviewed ? 'Rating submitted.' : subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                if (reviewed) ...[
                  const SizedBox(height: 5),
                  _StaticStars(rating: existingReview!.rating, size: 15),
                ],
              ],
            ),
          ),
          if (reviewed)
            const Icon(Icons.check_circle_rounded, color: AppColors.green)
          else
            OutlinedButton(
              onPressed: onRate,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
              ),
              child: const Text('Rate'),
            ),
        ],
      ),
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  final double average;
  final int reviewCount;
  final Map<int, int> distribution;

  const _RatingSummaryCard({
    required this.average,
    required this.reviewCount,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Column(
              children: [
                Text(
                  average.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                _StaticStars(rating: average.round(), size: 16),
                const SizedBox(height: 5),
                Text(
                  '$reviewCount reviews',
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                for (var rating = 5; rating >= 1; rating--)
                  _DistributionRow(
                    rating: rating,
                    count: distribution[rating] ?? 0,
                    total: reviewCount,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final int rating;
  final int count;
  final int total;

  const _DistributionRow({
    required this.rating,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              '$rating',
              style: const TextStyle(color: AppColors.muted, fontSize: 9),
            ),
          ),
          const Icon(Icons.star_rounded, color: AppColors.gold, size: 11),
          const SizedBox(width: 5),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.green),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 14,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.muted, fontSize: 8.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final CustomerProductReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final date =
        '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                date,
                style: const TextStyle(color: AppColors.muted, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              _StaticStars(rating: review.rating, size: 15),
              if (review.verifiedPurchase) ...[
                const SizedBox(width: 7),
                const Icon(Icons.verified_rounded,
                    color: AppColors.green, size: 13),
                const SizedBox(width: 3),
                const Text(
                  'Verified order',
                  style: TextStyle(color: AppColors.muted, fontSize: 8.5),
                ),
              ],
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              review.comment,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InteractiveStars extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _InteractiveStars({
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => IconButton(
          onPressed: () => onChanged(index + 1),
          iconSize: 38,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}

class _StaticStars extends StatelessWidget {
  final int rating;
  final double size;

  const _StaticStars({
    required this.rating,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: AppColors.gold,
          size: size,
        ),
      ),
    );
  }
}
