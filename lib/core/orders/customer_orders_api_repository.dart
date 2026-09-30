import '../data/customer_repository.dart';

class CustomerOrdersApiRepository {
  final CustomerRepositoryContext context;
  const CustomerOrdersApiRepository(this.context);
  bool get usesApi => context.usesApi;

  Future<Map<String,dynamic>> list({int page=1}) => context.apiClient.getJson('/api/v1/customer/orders', query: {'page':page}, authenticated:true);
  Future<Map<String,dynamic>> detail(int orderId) => context.apiClient.getJson('/api/v1/customer/orders/$orderId', authenticated:true);
  Future<Map<String,dynamic>> timeline(int orderId) => context.apiClient.getJson('/api/v1/customer/orders/$orderId/delivery-timeline', authenticated:true);

  Future<Map<String,dynamic>> cancel(int orderId, String reason, String key) => context.apiClient.requestJson(
    'POST','/api/v1/customer/orders/$orderId/cancel',body:{'reason':reason},authenticated:true,retryable:true,headers:{'Idempotency-Key':key});
  Future<Map<String,dynamic>> refund(int orderId, String reason, String key) => context.apiClient.requestJson(
    'POST','/api/v1/customer/orders/$orderId/refunds',body:{'reason':reason},authenticated:true,retryable:true,headers:{'Idempotency-Key':key});
  Future<Map<String,dynamic>> issuePin(int orderId, String key) => context.apiClient.requestJson(
    'POST','/api/v1/customer/orders/$orderId/delivery-pin',authenticated:true,retryable:true,headers:{'Idempotency-Key':key});
  Future<Map<String,dynamic>> issueQr(int orderId, String key) => context.apiClient.requestJson(
    'POST','/api/v1/customer/orders/$orderId/delivery-qr',authenticated:true,retryable:true,headers:{'Idempotency-Key':key});
}
