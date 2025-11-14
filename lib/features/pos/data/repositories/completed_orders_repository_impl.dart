import 'package:pos_flutter_app/features/pos/data/datasources/completed_orders_local_datasource.dart';
import 'package:pos_flutter_app/features/pos/data/models/completed_order_model.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/completed_order.dart';
import 'package:pos_flutter_app/features/pos/domain/repositories/completed_orders_repository.dart';

class CompletedOrdersRepositoryImpl implements CompletedOrdersRepository {
  final CompletedOrdersLocalDataSource localDataSource;

  CompletedOrdersRepositoryImpl({required this.localDataSource});

  @override
  Future<List<CompletedOrder>> getCompletedOrders() async {
    try {
      final orderModels = await localDataSource.getCompletedOrders();
      final orders = orderModels.map((model) => model.toEntity()).toList();
      orders.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return orders;
    } catch (e) {
      throw Exception('Error al obtener órdenes completadas: $e');
    }
  }

  @override
  Future<void> saveCompletedOrder(CompletedOrder order) async {
    try {
      final orderModel = CompletedOrderModel.fromEntity(order);
      await localDataSource.saveCompletedOrder(orderModel);
    } catch (e) {
      throw Exception('Error al guardar orden completada: $e');
    }
  }

  @override
  Future<List<CompletedOrder>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final orderModels =
          await localDataSource.getOrdersByDateRange(startDate, endDate);
      final orders = orderModels.map((model) => model.toEntity()).toList();
      orders.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return orders;
    } catch (e) {
      throw Exception('Error al obtener órdenes por rango de fechas: $e');
    }
  }

  @override
  Future<CompletedOrder?> getOrderById(String orderId) async {
    try {
      final orderModel = await localDataSource.getOrderById(orderId);
      return orderModel?.toEntity();
    } catch (e) {
      throw Exception('Error al obtener orden por ID: $e');
    }
  }

  @override
  Future<double> getTotalSalesByDate(DateTime date) async {
    try {
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final orders = await getOrdersByDateRange(startDate, endDate);

      double totalSales = 0.0;
      for (final order in orders) {
        totalSales += order.total;
      }

      return totalSales;
    } catch (e) {
      throw Exception('Error al calcular ventas totales por fecha: $e');
    }
  }
}
