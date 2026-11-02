import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_prefs.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import 'package:shared_preferences/shared_preferences.dart';

CustomerDisplaySnapshot buildCustomerDisplayAdvertisingSnapshot(
  BuildContext? context,
) {
  final prefs = di.sl<SharedPreferences>();
  var products = CustomerDisplayPrefs.adProducts(prefs);

  if (context != null && context.mounted) {
    try {
      final state = context.read<ProductBloc>().state;
      if (state is ProductLoaded) {
        products = CustomerDisplayPrefs.onSaleProductsFromCatalog(
          state.allProducts,
        );
        CustomerDisplayPrefs.cacheAdProducts(prefs, products);
      }
    } catch (_) {}
  }

  return CustomerDisplaySnapshot.advertising(
    adTitle: CustomerDisplayPrefs.adTitle(prefs),
    adMessage: CustomerDisplayPrefs.adMessage(prefs),
    adProducts: products,
  );
}
