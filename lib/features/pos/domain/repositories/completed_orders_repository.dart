import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';

abstract class CompletedOrdersRepository {
  // Local methods
  Future<List<CompletedOrder>> getCompletedOrders();
  Future<void> saveCompletedOrder(CompletedOrder order);
  Future<List<CompletedOrder>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate);
  Future<CompletedOrder?> getOrderById(String orderId);
  Future<double> getTotalSalesByDate(DateTime date);
  
  // Remote methods
  Future<List<CompletedOrder>> getCompletedOrdersFromRemote({int skip = 0, int limit = 10, bool? onlySales});
  Future<List<CompletedOrder>> getOrdersByDateRangeFromRemote(
      DateTime startDate, {DateTime? endDate, int skip = 0, int limit = 10, bool? onlySales});
  Future<CompletedOrder?> getOrderByIdFromRemote(String orderId);
  Future<CompletedOrder?> convertToCreditNote(String ticketId);
}
