import 'dart:convert';

import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerDisplayPrefs {
  static const enabledKey = 'customer_display_enabled';
  static const adTitleKey = 'customer_display_ad_title';
  static const adMessageKey = 'customer_display_ad_message';
  static const adProductsKey = 'customer_display_ad_products';
  static const adIdleSecondsKey = 'customer_display_ad_idle_seconds';

  static const defaultAdTitle = 'Promociones';
  static const defaultAdMessage = '';

  static const defaultAdIdleSeconds = 60;

  static const idleSecondsOptions = <int>[
    0,
    30,
    60,
    120,
    180,
    300,
  ];

  static String adTitle(SharedPreferences prefs) {
    final value = prefs.getString(adTitleKey)?.trim() ?? '';
    return value.isEmpty ? defaultAdTitle : value;
  }

  static String adMessage(SharedPreferences prefs) {
    return prefs.getString(adMessageKey)?.trim() ?? defaultAdMessage;
  }

  static int adIdleSeconds(SharedPreferences prefs) {
    return prefs.getInt(adIdleSecondsKey) ?? defaultAdIdleSeconds;
  }

  static String idleSecondsLabel(int seconds) {
    if (seconds <= 0) return 'Desactivado (solo fuera del POS)';
    if (seconds < 60) return '$seconds segundos';
    final minutes = seconds ~/ 60;
    return minutes == 1 ? '1 minuto' : '$minutes minutos';
  }

  /// Cache del último set de productos en oferta (is_on_sale = 1).
  static List<CustomerDisplayAdProduct> adProducts(SharedPreferences prefs) {
    final raw = prefs.getString(adProductsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => CustomerDisplayAdProduct.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static List<CustomerDisplayAdProduct> onSaleProductsFromCatalog(
    Iterable<Product> products,
  ) {
    return products
        .where((p) => p.isOnSale)
        .map(CustomerDisplayAdProduct.fromProduct)
        .toList();
  }

  static Future<void> saveAdvertising(
    SharedPreferences prefs, {
    required String title,
    required String message,
    required int idleSeconds,
    List<CustomerDisplayAdProduct>? products,
  }) async {
    await prefs.setString(adTitleKey, title.trim());
    await prefs.setString(adMessageKey, message.trim());
    await prefs.setInt(adIdleSecondsKey, idleSeconds < 0 ? 0 : idleSeconds);
    if (products != null) {
      await prefs.setString(
        adProductsKey,
        jsonEncode(products.map((e) => e.toJson()).toList()),
      );
    }
  }

  static Future<void> cacheAdProducts(
    SharedPreferences prefs,
    List<CustomerDisplayAdProduct> products,
  ) async {
    await prefs.setString(
      adProductsKey,
      jsonEncode(products.map((e) => e.toJson()).toList()),
    );
  }
}
