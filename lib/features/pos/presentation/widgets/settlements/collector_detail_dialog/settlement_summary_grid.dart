import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_collectors_detail_response_model.dart';

class SettlementSummaryGrid extends StatelessWidget {
  final PendingCollectorsDetailResponseModel detail;
  final VoidCallback? onCanceledItemsTap;

  const SettlementSummaryGrid({
    super.key,
    required this.detail,
    this.onCanceledItemsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canceledCount = detail.canceledItemsCount ?? 0;

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
            _buildMetricCard(
              title: 'Facturación',
              count: detail.invoiceCount ?? 0,
              total: (detail.invoiceTotal ?? 0.0).formatToCurrency(),
              iconColor: AppColors.primary,
              isDark: isDark,
            ),
            _buildMetricCard(
              title: 'Notas de Crédito',
              count: detail.creditNoteCount ?? 0,
              total: (detail.creditNoteTotal ?? 0.0).formatToCurrency(),
              iconColor: AppColors.error,
              isDark: isDark,
            ),
            _buildMetricCard(
              title: 'Artículos Cancelados',
              count: canceledCount,
              total: '$canceledCount unid.',
              iconColor: AppColors.accent,
              isDark: isDark,
              showTotalOnly: true,
              onTap: canceledCount > 0 ? onCanceledItemsTap : null,
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
    VoidCallback? onTap,
  }) {
    final card = Container(
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
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
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

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
        child: card,
      ),
    );
  }
}
