import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/search_bar.dart/search_weight_helper.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/search_bar.dart/weight_input_dialog.dart';

class SearchProcessor {
  static Future<void> processCode({
    required BuildContext context,
    required String rawCode,
    required TextEditingController searchController,
    required VoidCallback onClearSearch,
  }) async {
    final code = rawCode.trim();
    if (code.isEmpty) return;

    final uiState = context.read<UiBloc>().state;
    int qty = 1;
    bool isDeleteMode = false;
    bool isBarcodeMode = false;

    if (uiState is UiLoaded) {
      qty = uiState.selectedQuantity;
      isDeleteMode = uiState.isDeleteMode;
      isBarcodeMode = uiState.isBarcodeSearchEnabled;
    }

    final productBloc = context.read<ProductBloc>();
    final prodState = productBloc.state;
    Product? found;
    BarcodeModel? matchedBarcode;
    double? weightKg;
    double? calculatedUnitPrice;

    final inMemoryProducts =
        prodState is ProductLoaded ? prodState.products : <Product>[];

    if (isBarcodeMode) {
      final parsedWeight = tryParseWeightBarcode(code);
      if (parsedWeight != null) {
        weightKg = parsedWeight.weightKg;
        found = matchWeightedProductLocal(
          inMemoryProducts,
          parsedWeight.productKey,
        );
        if (found != null) {
          debugPrint(
            'BARCODE_FALLBACK: peso hit LOCAL plu=${parsedWeight.productKey} '
            'weightKg=$weightKg productId=${found.id}',
          );
        } else {
          final articleId = int.tryParse(parsedWeight.productKey);
          if (articleId != null) {
            debugPrint(
              'BARCODE_FALLBACK: peso MISS local → API article_id=$articleId '
              '(plu=${parsedWeight.productKey}) weightKg=$weightKg',
            );
            found = await productBloc.findByArticleId(articleId);
          }
        }
        if (found != null) {
          calculatedUnitPrice =
              calculateWeightedLineTotal(found, weightKg);
        }
      } else {
        final normalizedCode = normalizeBarcode(code);
        for (var product in inMemoryProducts) {
          if (product.barcodes != null) {
            for (var barcode in product.barcodes!) {
              if (barcodesMatch(barcode.barcode, normalizedCode)) {
                found = product;
                matchedBarcode = barcode;
                break;
              }
            }
            if (found != null) break;
          }
        }
        if (found != null) {
          debugPrint(
            'BARCODE_FALLBACK: barcode hit LOCAL code=$normalizedCode '
            'productId=${found.id}',
          );
        } else {
          debugPrint(
            'BARCODE_FALLBACK: barcode MISS local → API code=$normalizedCode',
          );
          found = await productBloc.findByBarcode(normalizedCode);
          if (found != null && found.barcodes != null) {
            for (var barcode in found.barcodes!) {
              if (barcodesMatch(barcode.barcode, normalizedCode)) {
                matchedBarcode = barcode;
                break;
              }
            }
            matchedBarcode ??=
                found.barcodes!.isNotEmpty ? found.barcodes!.first : null;
          }
        }
      }
    } else if (prodState is ProductLoaded) {
      try {
        final productCode = int.parse(code);
        found = prodState.products.cast<Product?>().firstWhere(
              (p) => p!.id == productCode,
              orElse: () => null,
            );
      } catch (_) {
        found = null;
      }
    }

    if (!context.mounted) return;

    if (found == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto no encontrado: $code'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      searchController.clear();
      return;
    }

    // Pesaje manual: barcode 20/21 sin peso, o producto ponderable por código normal.
    final needsManualWeight =
        (weightKg != null && weightKg <= 0) ||
            (weightKg == null && isProductWeighted(found));

    if (needsManualWeight) {
      searchController.clear();
      onClearSearch();

      final manualWeight = await showWeightInputDialog(
        context,
        product: found,
        isDeleteMode: isDeleteMode,
      );

      if (!context.mounted) return;

      if (manualWeight == null || manualWeight <= 0) {
        context.read<UiBloc>().add(ResetQuantity());
        return;
      }

      weightKg = manualWeight;
      calculatedUnitPrice = calculateWeightedLineTotal(found, manualWeight);
    }

    int finalQuantity = qty;
    if (matchedBarcode != null && weightKg == null) {
      finalQuantity = qty * (matchedBarcode.units ?? 1);

      String tipoVentaMsg = '';
      switch (matchedBarcode.type) {
        case 1:
          tipoVentaMsg = 'Unidad';
          break;
        case 2:
          tipoVentaMsg = 'Pack (${matchedBarcode.units} unidades)';
          break;
        case 3:
          tipoVentaMsg = 'Bulto (${matchedBarcode.units} unidades)';
          break;
      }

      if (tipoVentaMsg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tipo de venta: $tipoVentaMsg'),
            backgroundColor: AppColors.info,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }

    if (weightKg != null) {
      finalQuantity = 1;
    }

    final cartBloc = context.read<CartBloc>();
    if (isDeleteMode) {
      if (weightKg != null && calculatedUnitPrice != null) {
        cartBloc.add(RemoveQuantityFromCart(
          found.id.toString(),
          finalQuantity,
          isWeighted: true,
          weightKg: weightKg,
          pricePerKg: calculatedUnitPrice,
        ));
      } else {
        cartBloc
            .add(RemoveQuantityFromCart(found.id.toString(), finalQuantity));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${found.name} eliminado del carrito'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      if (weightKg != null && calculatedUnitPrice != null) {
        cartBloc.add(AddToCart(
          found,
          quantity: finalQuantity,
          isWeighted: true,
          weightKg: weightKg,
          pricePerKg: calculatedUnitPrice,
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${weightKg.toStringAsFixed(3)} kg × ${found.name} agregado',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        cartBloc.add(AddToCart(found, quantity: finalQuantity));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$finalQuantity x ${found.name} agregado'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }

    searchController.clear();
    onClearSearch();
    context.read<UiBloc>().add(ResetQuantity());
  }
}

/// Los barcodes se almacenan como [int], por lo que pierden ceros a la izquierda
String normalizeBarcode(String rawCode) {
  final trimmed = rawCode.trim();
  if (trimmed.isEmpty) return trimmed;
  final asInt = int.tryParse(trimmed);
  return asInt?.toString() ?? trimmed;
}

bool barcodesMatch(int? storedBarcode, String scannedCode) {
  if (storedBarcode == null) return false;
  return storedBarcode.toString() == scannedCode;
}