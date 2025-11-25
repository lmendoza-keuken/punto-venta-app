import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';

abstract class CompletedOrdersRepository {
  Future<List<CompletedOrder>> getCompletedOrders();
  Future<void> saveCompletedOrder(CompletedOrder order);
  Future<List<CompletedOrder>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate);
  Future<CompletedOrder?> getOrderById(String orderId);
  Future<double> getTotalSalesByDate(DateTime date);
}
