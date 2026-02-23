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
  Future<List<CompletedOrder>> getCompletedOrdersFromRemote();
  Future<List<CompletedOrder>> getOrdersByDateRangeFromRemote(
      DateTime startDate, {DateTime? endDate});
  Future<CompletedOrder?> getOrderByIdFromRemote(String orderId);
}
