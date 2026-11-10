import 'dart:convert';

import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/pos/data/models/completed_order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class CompletedOrdersLocalDataSource {
  Future<List<CompletedOrderModel>> getCompletedOrders();

  Future<void> saveCompletedOrder(CompletedOrderModel order);
  Future<void> clearLocalCache();

  Future<List<CompletedOrderModel>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate);
  Future<CompletedOrderModel?> getOrderById(String orderId);
}

class CompletedOrdersLocalDataSourceImpl
    implements CompletedOrdersLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String legacyBlobKey = 'COMPLETED_ORDERS';
  static const String indexKey = 'COMPLETED_ORDER_IDS';
  static const String orderKeyPrefix = 'COMPLETED_ORDER_';
  static const String purgedFlagKey = 'COMPLETED_ORDERS_PURGED_V1';

  CompletedOrdersLocalDataSourceImpl({required this.sharedPreferences});

  static String _orderKey(String id) => '$orderKeyPrefix$id';

  bool get _alreadyPurged =>
      sharedPreferences.getBool(purgedFlagKey) == true;

  @override
  Future<List<CompletedOrderModel>> getCompletedOrders() async {
    // Solo lectura residual (por si el purge aún no corrió).
    final legacy = sharedPreferences.getString(legacyBlobKey);
    if (legacy != null && legacy.isNotEmpty) {
      try {
        final decoded = json.decode(legacy);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => CompletedOrderModel.fromJson(
                    Map<String, dynamic>.from(
                      e.map((k, v) => MapEntry(k.toString(), v)),
                    ),
                  ))
              .toList();
        }
      } catch (e) {
        AppLogger.warn('CompletedOrdersLocal: legacy read fail error=$e');
      }
    }

    final ids = sharedPreferences.getStringList(indexKey) ?? const <String>[];
    final orders = <CompletedOrderModel>[];
    for (final id in ids) {
      final order = _readOrder(id);
      if (order != null) orders.add(order);
    }
    return orders;
  }

  @override
  Future<void> saveCompletedOrder(CompletedOrderModel order) async {
    await clearLocalCache();
  }

  @override
  Future<void> clearLocalCache() async {
    if (_alreadyPurged && !_hasAnyCompletedOrderKeys()) {
      return;
    }

    final sw = Stopwatch()..start();
    final keysToRemove = sharedPreferences.getKeys().where((key) {
      return key == legacyBlobKey ||
          key == indexKey ||
          key.startsWith(orderKeyPrefix);
    }).toList();

    for (final key in keysToRemove) {
      await sharedPreferences.remove(key);
    }
    await sharedPreferences.setBool(purgedFlagKey, true);

    sw.stop();
    AppLogger.info(
      'CompletedOrdersLocal: cache cleared '
      'removedKeys=${keysToRemove.length} '
      'elapsedMs=${sw.elapsedMilliseconds}',
    );
  }

  bool _hasAnyCompletedOrderKeys() {
    if (sharedPreferences.containsKey(legacyBlobKey)) return true;
    if (sharedPreferences.containsKey(indexKey)) return true;
    return sharedPreferences
        .getKeys()
        .any((key) => key.startsWith(orderKeyPrefix));
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
    final fromKey = _readOrder(orderId);
    if (fromKey != null) return fromKey;

    final all = await getCompletedOrders();
    try {
      return all.firstWhere((order) => order.id == orderId);
    } catch (_) {
      return null;
    }
  }

  CompletedOrderModel? _readOrder(String id) {
    final raw = sharedPreferences.getString(_orderKey(id));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        return CompletedOrderModel.fromJson(decoded);
      }
      if (decoded is Map) {
        return CompletedOrderModel.fromJson(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    } catch (e) {
      AppLogger.warn('CompletedOrdersLocal: bad order id=$id error=$e');
    }
    return null;
  }
}
