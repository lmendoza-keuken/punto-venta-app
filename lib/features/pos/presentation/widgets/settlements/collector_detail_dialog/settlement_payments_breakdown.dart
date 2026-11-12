import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_collectors_detail_response_model.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/confirmation_helpers.dart';

class SettlementPaymentsBreakdown extends StatelessWidget {
  final List<PaymentBreakdown>? payments;

  const SettlementPaymentsBreakdown({
    super.key,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (payments == null || payments!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXL),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                'No hay cobros registrados',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.sidebarDarkSurface : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.borderRadiusS - 1),
                topRight: Radius.circular(AppDimensions.borderRadiusS - 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Método de Pago',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Monto Cobrado',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments!.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final payment = payments![index];
              final amountVal = payment.totalAmount ?? 0.0;
              final description = payment.description ?? 'Método Desconocido';
              final icon = getPaymentMethodIcon(description, description);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.paddingM,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.sidebarDarkSurface
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      amountVal.formatToCurrency(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
