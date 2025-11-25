import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/completed_orders_repository.dart';

class GetReportsUsecase {
  final CompletedOrdersRepository repository;

  GetReportsUsecase(this.repository);

  Future<List<CompletedOrder>> getAllCompletedOrders() async {
    return await repository.getCompletedOrders();
  }

  Future<List<CompletedOrder>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate) async {
    return await repository.getOrdersByDateRange(startDate, endDate);
  }

  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final orders = await repository.getOrdersByDateRange(startDate, endDate);

    final totalSales = orders.fold(0.0, (sum, order) => sum + order.total);
    final totalOrders = orders.length;
    final totalItems = orders.fold(0, (sum, order) => sum + order.totalItems);
    final totalTax = orders.fold(0.0, (sum, order) => sum + order.totalTax);

    return {
      'total_sales': totalSales,
      'total_orders': totalOrders,
      'total_items': totalItems,
      'total_tax': totalTax,
      'orders': orders,
    };
  }

  Future<CompletedOrder?> getOrderById(String orderId) async {
    return await repository.getOrderById(orderId);
  }
}
