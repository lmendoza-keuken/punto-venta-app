import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/pos/data/models/branch_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/vat_category_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';

class VatPerceptionCalculator {
  static Map<String, dynamic> calculateVatPerceptionWithBreakdown({
    required List<CartItem> cartItems,
    required BranchResponseModel? branch,
    required VatCategoryModel? vatCategory,
  }) {
    final emptyResult = {
      'total': 0.0,
      'byPerception': <double, double>{},
    };

    if (branch == null || vatCategory == null || cartItems.isEmpty) {
      return emptyResult;
    }

    // Condición 1: La categoría de IVA del cliente debe tener applyPerVat: true
    if (vatCategory.applyPerVat != true) {
      debugPrint(
          '[VAT_PERC_CALC] Categoría de IVA no aplica percepción de IVA');
      return emptyResult;
    }
    debugPrint(
        '[VAT_PERC_CALC] Condición 1: Categoría de IVA aplica percepción');

    // Condición 2: La sucursal debe tener applyPerVat: true
    if (branch.applyPerVat != true) {
      debugPrint('[VAT_PERC_CALC] Sucursal no aplica percepción de IVA');
      return emptyResult;
    }
    debugPrint('[VAT_PERC_CALC] Condición 2: Sucursal aplica percepción');

    // Agrupar subtotales por vat_perception
    final Map<double, double> subtotalsByPerception = {};

    for (final item in cartItems) {
      final vatPerception = item.product.vatPerception;

      if (vatPerception == null || vatPerception == 0) {
        continue;
      }

      // Calcular subtotal del item
      final double subtotal;
      if (item.isWeighted == true) {
        subtotal = (item.pricePerKg ?? item.product.price ?? 0.0);
      } else {
        subtotal = (item.product.price ?? 0.0) * item.quantity;
      }

      // Acumular subtotal para esta vat_perception
      subtotalsByPerception.update(
        vatPerception,
        (prev) => prev + subtotal,
        ifAbsent: () => subtotal,
      );
    }

    // Calcular el monto de percepción para cada grupo
    final Map<double, double> amountsByPerception = {};
    double totalPerception = 0.0;

    for (final entry in subtotalsByPerception.entries) {
      final vatPerception = entry.key;
      final subtotal = entry.value;
      final amount = subtotal * (vatPerception / 100);

      amountsByPerception[vatPerception] = amount;
      totalPerception += amount;

      debugPrint(
        '[VAT_PERC_CALC]   Percep. ${vatPerception}%: subtotal \$$subtotal → monto \$$amount',
      );
    }

    debugPrint('[VAT_PERC_CALC]   Total percepción: \$$totalPerception');

    // Condición 3: TotalPercep > per_vat_amount
    final perVatAmount = branch.perVatAmount?.toDouble() ?? 0.0;
    if (totalPerception <= perVatAmount) {
      debugPrint(
        '[VAT_PERC_CALC] Total (\$$totalPerception) <= Mínimo (\$$perVatAmount)',
      );
      return emptyResult;
    }
    debugPrint(
      '[VAT_PERC_CALC] Condición 3: Total (\$$totalPerception) > Mínimo (\$$perVatAmount)',
    );

    return {
      'total': totalPerception,
      'byPerception': amountsByPerception,
    };
  }

  /// Calcula solo el monto total de percepción de IVA
  static double calculateVatPerception({
    required List<CartItem> cartItems,
    required BranchResponseModel? branch,
    required VatCategoryModel? vatCategory,
  }) {
    final result = calculateVatPerceptionWithBreakdown(
      cartItems: cartItems,
      branch: branch,
      vatCategory: vatCategory,
    );
    return result['total'] ?? 0.0;
  }

  /// Verifica si se debe calcular percepción de IVA
  static bool shouldCalculateVatPerception({
    required List<CartItem> cartItems,
    required BranchResponseModel? branch,
    required VatCategoryModel? vatCategory,
  }) {
    if (branch == null || vatCategory == null || cartItems.isEmpty) {
      return false;
    }

    // Verificar si la categoría de IVA aplica percepción
    if (vatCategory.applyPerVat != true) {
      return false;
    }

    // Verificar si la sucursal aplica percepción
    if (branch.applyPerVat != true) {
      return false;
    }

    // Verificar si hay al menos un producto con vat_perception
    final hasVatPerception = cartItems.any(
      (item) =>
          item.product.vatPerception != null && item.product.vatPerception! > 0,
    );

    return hasVatPerception;
  }
}
