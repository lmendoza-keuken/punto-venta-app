import 'dart:convert';
import 'package:pos_flutter_app/features/pos/data/models/saved_order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SavedOrdersLocalDataSource {
  Future<List<SavedOrderModel>> getSavedOrders();
  Future<void> saveOrder(SavedOrderModel order);
  Future<void> deleteOrder(String orderId);
  Future<SavedOrderModel?> getOrderById(String orderId);
}

class SavedOrdersLocalDataSourceImpl implements SavedOrdersLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String savedOrdersKey = 'SAVED_ORDERS';

  SavedOrdersLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<SavedOrderModel>> getSavedOrders() async {
    final jsonString = sharedPreferences.getString(savedOrdersKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => SavedOrderModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> saveOrder(SavedOrderModel order) async {
    final orders = await getSavedOrders();

    // Verificar si ya existe un pedido con el mismo ID y actualizar
    final existingIndex = orders.indexWhere((o) => o.id == order.id);
    if (existingIndex != -1) {
      orders[existingIndex] = order;
    } else {
      orders.add(order);
    }

    final jsonString = json.encode(orders.map((o) => o.toJson()).toList());
    await sharedPreferences.setString(savedOrdersKey, jsonString);
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    final orders = await getSavedOrders();
    final updatedOrders = orders.where((order) => order.id != orderId).toList();

    final jsonString =
        json.encode(updatedOrders.map((o) => o.toJson()).toList());
    await sharedPreferences.setString(savedOrdersKey, jsonString);
  }

  @override
  Future<SavedOrderModel?> getOrderById(String orderId) async {
    final orders = await getSavedOrders();
    try {
      return orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }
}
