import 'package:punto_venta_app/core/constants/ticket_types.dart';
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

    return buildSummaryFromOrders(orders);
  }

  Map<String, dynamic> buildSummaryFromOrders(List<CompletedOrder> orders) {
    return {
      'total_sales': orders.fold(0.0, (sum, order) {
        if (TicketType.isNotaCredito(order.typeCode)) {
          return sum - order.total;
        } else {
          return sum + order.total;
        }
      }),
      'total_orders': orders.length,
      'total_items': orders.fold(0, (sum, order) {
        if (TicketType.isNotaCredito(order.typeCode)) {
          return sum - order.totalItems;
        } else {
          return sum + order.totalItems;
        }
      }),
      'total_tax': orders.fold(0.0, (sum, order) {
        if (TicketType.isNotaCredito(order.typeCode)) {
          return sum - order.totalTax;
        } else {
          return sum + order.totalTax;
        }
      }),
      'orders': orders,
    };
  }

  Future<CompletedOrder?> getOrderById(String orderId) async {
    return await repository.getOrderById(orderId);
  }

  // Remote methods
  Future<List<CompletedOrder>> getAllCompletedOrdersFromRemote(
      {int skip = 0, int limit = 10, String? typeCode}) async {
    return await repository.getCompletedOrdersFromRemote(
        skip: skip, limit: limit, typeCode: typeCode);
  }

  Future<List<CompletedOrder>> getOrdersByDateRangeFromRemote(
      DateTime startDate,
      {DateTime? endDate,
      int skip = 0,
      int limit = 10,
      String? typeCode}) async {
    return await repository.getOrdersByDateRangeFromRemote(startDate,
        endDate: endDate, skip: skip, limit: limit, typeCode: typeCode);
  }

  Future<Map<String, dynamic>> getDailySummaryFromRemote(DateTime date,
      {int skip = 0, int limit = 10, String? typeCode}) async {
    // Fecha de inicio (solo enviar esta fecha para obtener el día completo)
    final startDate = DateTime(date.year, date.month, date.day);

    // Obtener órdenes del día desde remote (sin endDate para obtener solo ese día)
    final orders = await repository.getOrdersByDateRangeFromRemote(startDate,
        skip: skip, limit: limit, typeCode: typeCode);

    return buildSummaryFromOrders(orders);
  }

  /// Carga órdenes por chunks y emite el summary acumulado tras cada página
  /// (mismo patrón que productos).
  Stream<({Map<String, dynamic> summary, bool hasMore})>
      streamOrdersSummaryByDateRange(
    DateTime startDate, {
    DateTime? endDate,
    int chunkSize = 10,
    String? typeCode,
  }) async* {
    final allOrders = <CompletedOrder>[];
    int skip = 0;
    bool hasMore = true;

    while (hasMore) {
      final chunk = await repository.getOrdersByDateRangeFromRemote(
        startDate,
        endDate: endDate,
        skip: skip,
        limit: chunkSize,
        typeCode: typeCode,
      );

      allOrders.addAll(chunk);
      hasMore = chunk.length >= chunkSize;

      yield (
        summary: buildSummaryFromOrders(List<CompletedOrder>.from(allOrders)),
        hasMore: hasMore,
      );

      if (hasMore) {
        skip += chunkSize;
      }
    }
  }

  Future<CompletedOrder?> getOrderByIdFromRemote(String orderId) async {
    return await repository.getOrderByIdFromRemote(orderId);
  }
}
