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
    final jsonString = sharedPreferences.getString(completedOrdersKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => CompletedOrderModel.fromJson(json))
          .toList();
    }
    return [];
  }

  @override
  Future<void> saveCompletedOrder(CompletedOrderModel order) async {
    final orders = await getCompletedOrders();
    orders.add(order);

    final jsonString = json.encode(orders.map((o) => o.toJson()).toList());
    await sharedPreferences.setString(completedOrdersKey, jsonString);
  }

  @override
  Future<List<CompletedOrderModel>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate) async {
    final orders = await getCompletedOrders();
    return orders.where((order) {
      return order.completedAt
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          order.completedAt.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<CompletedOrderModel?> getOrderById(String orderId) async {
    final orders = await getCompletedOrders();
    try {
      return orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }
}
