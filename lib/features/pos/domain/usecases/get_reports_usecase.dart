import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/completed_orders_repository.dart';

class GetReportsUsecase {
  final CompletedOrdersRepository repository;

  GetReportsUsecase(this.repository);

  // Local methods
  Future<List<CompletedOrder>> getAllCompletedOrders() async {
    return await repository.getCompletedOrders();
  }

  Future<List<CompletedOrder>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate) async {
    return await repository.getOrdersByDateRange(startDate, endDate);
  }

  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    // Fecha de inicio y fin del día
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Obtener órdenes del día
    final orders = await repository.getOrdersByDateRange(startDate, endDate);

    // stats diarios
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

  // Remote methods
  Future<List<CompletedOrder>> getAllCompletedOrdersFromRemote({int skip = 0, int limit = 10}) async {
    return await repository.getCompletedOrdersFromRemote(skip: skip, limit: limit);
  }

  Future<List<CompletedOrder>> getOrdersByDateRangeFromRemote(
      DateTime startDate, {DateTime? endDate, int skip = 0, int limit = 10}) async {
    return await repository.getOrdersByDateRangeFromRemote(startDate, endDate: endDate, skip: skip, limit: limit);
  }

  Future<Map<String, dynamic>> getDailySummaryFromRemote(DateTime date, {int skip = 0, int limit = 10}) async {
    // Fecha de inicio (solo enviar esta fecha para obtener el día completo)
    final startDate = DateTime(date.year, date.month, date.day);

    // Obtener órdenes del día desde remote (sin endDate para obtener solo ese día)
    final orders = await repository.getOrdersByDateRangeFromRemote(startDate, skip: skip, limit: limit);

    // stats diarios
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

  Future<CompletedOrder?> getOrderByIdFromRemote(String orderId) async {
    return await repository.getOrderByIdFromRemote(orderId);
  }
}
