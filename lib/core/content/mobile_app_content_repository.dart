import '../data/customer_repository.dart';
import 'mobile_app_content_models.dart';

class MobileAppContentRepository {
  final CustomerRepositoryContext context;

  const MobileAppContentRepository(this.context);

  Future<MobileAppContentSnapshot> load({
    int? branchId,
    String language = 'en',
    String? market,
    String? fulfillment,
  }) async {
    if (!context.usesApi) return const MobileAppContentSnapshot();
    final payload = await context.apiClient.getJson(
      '/api/v1/customer/app-content',
      query: <String, Object?>{
        if (branchId != null) 'branch_id': branchId,
        'language': language,
        if (market != null && market.isNotEmpty) 'market': market,
        if (fulfillment != null && fulfillment.isNotEmpty)
          'fulfillment': fulfillment,
      },
    );
    final data = payload['data'];
    return MobileAppContentSnapshot.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{},
    );
  }
}
