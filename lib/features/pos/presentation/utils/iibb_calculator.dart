import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/pos/data/models/branch_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/vat_category_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';

class IibbCalculator {
  static Map<String, double?> calculateIibbWithPercentage({
    required Client? client,
    required BranchResponseModel? branch,
    required VatCategoryModel? vatCategory,
    required double subtotal,
    required double totalWithVat,
  }) {
    // Validate required data
    if (client == null || branch == null || vatCategory == null) {
      return {'amount': 0.0, 'percentage': null};
    }

    // Check condition 1: pdv.vat_category_id != 3 (not "Consumidor final")
    if (client.vatCategoryId == 3) {
      return {'amount': 0.0, 'percentage': null};
    }
    debugPrint('[IIBB_CALC]  Condición 1: Cliente NO es Consumidor Final');

    // Check condition 2: branch.apply_per_iibb == true
    if (branch.applyPerIibb != true) {
      return {'amount': 0.0, 'percentage': null};
    }
    debugPrint('[IIBB_CALC]  Condición 2: Sucursal aplica IIBB');

    // Check condition 3: totalWithVat >= branch.per_iibb_amount
    final perIibbAmount = branch.perIibbAmount?.toDouble() ?? 0.0;
    if (totalWithVat < perIibbAmount) {
      return {'amount': 0.0, 'percentage': null};
    }
    debugPrint(
        '[IIBB_CALC]  Condición 3: Total (\$$totalWithVat) >= Mínimo (\$$perIibbAmount)');

    // Get client's IIBB tax rates for this branch
    final iibbTaxRates = client.iibbTaxRates ?? [];
    final branchId = branch.branchId;

    if (branchId == null) {
      return {'amount': 0.0, 'percentage': null};
    }

    // Filter rates for the current branch
    final applicableRates =
        iibbTaxRates.where((rate) => rate.branchId == branchId).toList();

    if (applicableRates.isEmpty) {
      return {'amount': 0.0, 'percentage': null};
    }

    // Calculate IIBB based on ib_perception
    final ibPerception = vatCategory.ibPerception?.toUpperCase() ?? '';
    double iibbAmount = 0.0;
    double totalPercentage = 0.0;


    if (ibPerception == 'NET') {
      // Use net amount (subtotal without VAT)
      for (final rate in applicableRates) {
        final rateAmount = subtotal * (rate.taxRate / 100);
        iibbAmount += rateAmount;
        totalPercentage += rate.taxRate;
        final rateType =
            rate.period == null ? 'default sucursal' : 'período ${rate.period}';
        debugPrint(
            '[IIBB_CALC]    Tasa ${rate.taxRate}% ($rateType) sobre NET (\$$subtotal) = \$$rateAmount');
      }
    } else {
      // Use total amount with VAT
      for (final rate in applicableRates) {
        final rateAmount = totalWithVat * (rate.taxRate / 100);
        iibbAmount += rateAmount;
        totalPercentage += rate.taxRate;
        final rateType =
            rate.period == null ? 'default sucursal' : 'período ${rate.period}';
        debugPrint(
            '[IIBB_CALC]    Tasa ${rate.taxRate}% ($rateType) sobre TOT (\$$totalWithVat) = \$$rateAmount');
      }
    }

    return {'amount': iibbAmount, 'percentage': totalPercentage};
  }

  /// Calculates IIBB tax based on client, branch, VAT category, and cart totals
  ///
  /// Returns the calculated IIBB amount, or 0.0 if IIBB doesn't apply
  static double calculateIibb({
    required Client? client,
    required BranchResponseModel? branch,
    required VatCategoryModel? vatCategory,
    required double subtotal,
    required double totalWithVat,
  }) {
    final result = calculateIibbWithPercentage(
      client: client,
      branch: branch,
      vatCategory: vatCategory,
      subtotal: subtotal,
      totalWithVat: totalWithVat,
    );
    return result['amount'] ?? 0.0;
  }

  /// Checks if IIBB calculation should be performed
  static bool shouldCalculateIibb({
    required Client? client,
    required BranchResponseModel? branch,
    required double totalWithVat,
  }) {
    if (client == null || branch == null) {
      return false;
    }

    // Check if not "Consumidor final"
    if (client.vatCategoryId == 3) {
      return false;
    }

    // Check if branch applies IIBB
    if (branch.applyPerIibb != true) {
      return false;
    }

    // Check minimum amount
    final perIibbAmount = branch.perIibbAmount?.toDouble() ?? 0.0;
    if (totalWithVat < perIibbAmount) {
      return false;
    }

    return true;
  }
}
