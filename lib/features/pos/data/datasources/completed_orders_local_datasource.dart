import 'dart:convert';
import 'package:punto_venta_app/features/pos/data/models/completed_order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class CompletedOrdersLocalDataSource {
  Future<List<CompletedOrderModel>> getCompletedOrders();
  Future<void> saveCompletedOrder(CompletedOrderModel order);
  Future<List<CompletedOrderModel>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate);
  Future<CompletedOrderModel?> getOrderById(String orderId);
}

class CompletedOrdersLocalDataSourceImpl
    implements CompletedOrdersLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String completedOrdersKey = 'COMPLETED_ORDERS';

  CompletedOrdersLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<CompletedOrderModel>> getCompletedOrders() async {
    try {
      final jsonString = sharedPreferences.getString(completedOrdersKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final decoded = json.decode(jsonString);
      if (decoded is List) {
        return (decoded)
            .whereType<Map<String, dynamic>>()
            .map((json) => CompletedOrderModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveCompletedOrder(CompletedOrderModel order) async {
    try {
      final orders = await getCompletedOrders();
      orders.add(order);

      final jsonString = json.encode(orders.map((o) => o.toJson()).toList());
      await sharedPreferences.setString(completedOrdersKey, jsonString);
    } catch (e) {
      throw Exception('Error al guardar orden: $e');
    }
  }

  @override
  Future<List<CompletedOrderModel>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final orders = await getCompletedOrders();
      return orders.where((order) {
        return order.completedAt
                .isAfter(startDate.subtract(const Duration(days: 1))) &&
            order.completedAt.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<CompletedOrderModel?> getOrderById(String orderId) async {
    try {
      final orders = await getCompletedOrders();
      return orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }
}
