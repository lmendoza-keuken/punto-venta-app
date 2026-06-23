import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/branch_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/vat_category_local_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/iibb_calculator.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/vat_perception_calculator.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/internal_tax_calculator.dart';

class OrderTaxesResult {
  final double subtotal;
  final double totalIva;
  final double iibbAmount;
  final double? iibbPercentage;
  final double vatPerceptionAmount;
  final Map<String, double> vatPerceptionByRate;
  final double internalTaxAmount;
  final double? internalTaxRate;
  final double totalAmount;

  const OrderTaxesResult({
    required this.subtotal,
    required this.totalIva,
    required this.iibbAmount,
    this.iibbPercentage,
    required this.vatPerceptionAmount,
    required this.vatPerceptionByRate,
    required this.internalTaxAmount,
    this.internalTaxRate,
    required this.totalAmount,
  });
}

class CalculateOrderTaxesUseCase {
  final PdvLocalDataSource pdvLocalDataSource;
  final BranchLocalDataSource branchLocalDataSource;
  final VatCategoryLocalDataSource vatCategoryLocalDataSource;

  CalculateOrderTaxesUseCase({
    required this.pdvLocalDataSource,
    required this.branchLocalDataSource,
    required this.vatCategoryLocalDataSource,
  });

  Future<OrderTaxesResult> call({
    required List<CartItem> items,
    required double subtotal,
    required double totalIva,
    required Client? client,
  }) async {
    // 1. Calculate internal tax
    final internalTaxResult = InternalTaxCalculator.calculateInternalTax(
      items: items,
    );
    final double computedInternalTax = internalTaxResult['total'] ?? 0.0;
    final double? internalTaxRate = internalTaxResult['rate'];

    // 2. Calculate client-specific taxes (IIBB and VAT Perceptions)
    double iibbAmount = 0.0;
    double? iibbPercentage;
    double vatPerceptionAmount = 0.0;
    Map<String, double> vatPerceptionByRate = {};

    if (client != null) {
      try {
        final pdvConfig = await pdvLocalDataSource.getPdvConfig();
        final branchId = pdvConfig?.branchId;

        if (branchId != null) {
          final branch = await branchLocalDataSource.getBranchById(branchId);
          final vatCategoryId = client.vatCategoryId;
          final allVatCategories =
              await vatCategoryLocalDataSource.getCachedVatCategories();
          final vatCategory = allVatCategories
              ?.where((cat) => cat.id == vatCategoryId)
              .firstOrNull;

          if (branch != null) {
            // IIBB
            final iibbResult = IibbCalculator.calculateIibbWithPercentage(
              client: client,
              branch: branch,
              vatCategory: vatCategory,
              subtotal: subtotal,
              totalWithVat: subtotal + totalIva,
            );
            iibbAmount = iibbResult['amount'] ?? 0.0;
            iibbPercentage = iibbResult['percentage'];

            // VAT Perception
            final vatPerceptionResult =
                VatPerceptionCalculator.calculateVatPerceptionWithBreakdown(
              cartItems: items,
              branch: branch,
              vatCategory: vatCategory,
            );
            vatPerceptionAmount = vatPerceptionResult['total'] ?? 0.0;
            final vatPerceptionByRateDouble =
                vatPerceptionResult['byPerception'] as Map<double, double>?;
            vatPerceptionByRate = vatPerceptionByRateDouble?.map(
                  (key, value) => MapEntry(key.toString(), value),
                ) ??
                {};
          }
        }
      } catch (e) {}
    }

    final totalAmount = subtotal +
        totalIva +
        iibbAmount +
        vatPerceptionAmount +
        computedInternalTax;

    return OrderTaxesResult(
      subtotal: subtotal,
      totalIva: totalIva,
      iibbAmount: iibbAmount,
      iibbPercentage: iibbPercentage,
      vatPerceptionAmount: vatPerceptionAmount,
      vatPerceptionByRate: vatPerceptionByRate,
      internalTaxAmount: computedInternalTax,
      internalTaxRate: internalTaxRate,
      totalAmount: totalAmount,
    );
  }
}
