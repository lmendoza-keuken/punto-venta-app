import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';

class InternalTaxCalculator {
  static Map<String, double> calculateInternalTax({
    required List<CartItem> items,
  }) {
    debugPrint('========== INTERNAL TAX CALCULATION START ==========');
    
    double totalInternalTax = 0.0;
    double totalInternalTaxRate = 0.0;
    double totalBaseAmount = 0.0;
    int itemsWithInternalTax = 0;

    for (final item in items) {
      final product = item.product;
      
      final internalTax = product.internalTax;
      final internalTaxRate = product.internalTaxRate;
      
      if (internalTax <= 0) {
        debugPrint('Product ${product.id} "${product.description}" - No internal tax');
        continue;
      }

      final basePrice = product.price ?? 0.0;
      final quantity = item.quantity;
      final fractional = product.fractional ?? 1;

      final itemTotalWithTax = (internalTax + basePrice) * quantity * fractional;
      
      final baseAmount = basePrice * quantity * fractional;
      final itemInternalTax = itemTotalWithTax - baseAmount;

      totalInternalTax += itemInternalTax;
      totalBaseAmount += baseAmount;
      
      if (internalTaxRate != null && internalTaxRate > 0) {
        totalInternalTaxRate += internalTaxRate * baseAmount;
        itemsWithInternalTax++;
      }

      debugPrint('Product ${product.id}: "${product.description}"');
      debugPrint('  - Internal Tax Amount: \$${internalTax.toStringAsFixed(2)}');
      debugPrint('  - Internal Tax Rate: ${internalTaxRate ?? 0}%');
      debugPrint('  - Base Price: \$${basePrice.toStringAsFixed(2)}');
      debugPrint('  - Quantity: $quantity');
      debugPrint('  - Fractional: $fractional');
      debugPrint('  - Base Amount: \$${baseAmount.toStringAsFixed(2)}');
      debugPrint('  - Item Internal Tax: \$${itemInternalTax.toStringAsFixed(2)}');
    }

    double averageRate = 0.0;
    if (totalBaseAmount > 0 && itemsWithInternalTax > 0) {
      averageRate = totalInternalTaxRate / totalBaseAmount;
    }

    debugPrint('---------- INTERNAL TAX SUMMARY ----------');
    debugPrint('Total Internal Tax: \$${totalInternalTax.toStringAsFixed(2)}');
    debugPrint('Average Rate: ${averageRate.toStringAsFixed(2)}%');
    debugPrint('Items with Internal Tax: $itemsWithInternalTax');
    debugPrint('========== INTERNAL TAX CALCULATION END ==========\n');

    return {
      'total': totalInternalTax,
      'rate': averageRate,
    };
  }

  static bool hasInternalTax(List<CartItem> items) {
    return items.any((item) => (item.product.internalTax) > 0);
  }

  static List<Map<String, dynamic>> getInternalTaxBreakdown(List<CartItem> items) {
    final breakdown = <Map<String, dynamic>>[];

    for (final item in items) {
      final product = item.product;
      final internalTax = product.internalTax;
      
      if (internalTax <= 0) continue;

      final basePrice = product.price ?? 0.0;
      final quantity = item.quantity;
      final fractional = product.fractional ?? 1;
      
      final itemTotalWithTax = (internalTax + basePrice) * quantity * fractional;
      final baseAmount = basePrice * quantity * fractional;
      final itemInternalTax = itemTotalWithTax - baseAmount;

      breakdown.add({
        'product_id': product.id,
        'product_name': product.description,
        'internal_tax_amount': internalTax,
        'internal_tax_rate': product.internalTaxRate ?? 0.0,
        'quantity': quantity,
        'fractional': fractional,
        'base_amount': baseAmount,
        'item_internal_tax': itemInternalTax,
      });
    }

    return breakdown;
  }
}
