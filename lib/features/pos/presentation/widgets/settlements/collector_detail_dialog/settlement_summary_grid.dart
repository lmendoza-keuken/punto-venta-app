import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_collectors_detail_response_model.dart';

class SettlementSummaryGrid extends StatelessWidget {
  final PendingCollectorsDetailResponseModel detail;

  const SettlementSummaryGrid({
    super.key,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 3 : 1;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppDimensions.paddingS,
            mainAxisSpacing: AppDimensions.paddingS,
            childAspectRatio: crossAxisCount == 3 ? 1.4 : 3.5,
          ),
          children: [
            // Invoice Card
            _buildMetricCard(
              title: 'Facturación',
              count: detail.invoiceCount ?? 0,
              total: (detail.invoiceTotal ?? 0.0).formatToCurrency(),
              iconColor: AppColors.primary,
              isDark: isDark,
            ),
            // Credit Note Card
            _buildMetricCard(
              title: 'Notas de Crédito',
              count: detail.creditNoteCount ?? 0,
              total: (detail.creditNoteTotal ?? 0.0).formatToCurrency(),
              iconColor: AppColors.error,
              isDark: isDark,
            ),
            // Canceled Items Card
            _buildMetricCard(
              title: 'Artículos Cancelados',
              count: detail.canceledItemsCount ?? 0,
              total: '${detail.canceledItemsCount ?? 0} unid.',
              iconColor: AppColors.accent,
              isDark: isDark,
              showTotalOnly: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required String total,
    required Color iconColor,
    required bool isDark,
    bool showTotalOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            total,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          if (!showTotalOnly) ...[
            const SizedBox(height: 2),
            Text(
              '$count comprobantes',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
