import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_collectors_detail_response_model.dart';

class SettlementSummaryGrid extends StatelessWidget {
  final PendingCollectorsDetailResponseModel detail;
  final VoidCallback? onCanceledItemsTap;
  final VoidCallback? onDisposedItemsTap;

  const SettlementSummaryGrid({
    super.key,
    required this.detail,
    this.onCanceledItemsTap,
    this.onDisposedItemsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canceledCount = detail.canceledItemsCount ?? 0;
    final disposedCount = detail.disposedItemsCount;
    final showDisposedCard = disposedCount != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardCount = showDisposedCard ? 4 : 3;
        final crossAxisCount = constraints.maxWidth > 720
            ? cardCount
            : constraints.maxWidth > 420
                ? 2
                : 1;
        final compact = constraints.maxWidth < LayoutSpec.compactBreakpoint;
        // Fixed height so title + amount + "N comprobantes" always fit on mobile.
        final mainAxisExtent = 108.0;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppDimensions.paddingS,
            mainAxisSpacing: AppDimensions.paddingS,
            mainAxisExtent: mainAxisExtent,
          ),
          children: [
            _buildMetricCard(
              title: 'Facturación',
              count: detail.invoiceCount ?? 0,
              total: (detail.invoiceTotal ?? 0.0).formatToCurrency(),
              totalColor: AppColors.success,
              isDark: isDark,
              compact: compact,
            ),
            _buildMetricCard(
              title: 'Notas de Crédito',
              count: detail.creditNoteCount ?? 0,
              total: (detail.creditNoteTotal ?? 0.0).formatToCurrency(),
              totalColor: AppColors.error,
              isDark: isDark,
              compact: compact,
            ),
            _buildMetricCard(
              title: 'Artículos Cancelados',
              count: canceledCount,
              total: '$canceledCount unid.',
              totalColor: AppColors.warning,
              isDark: isDark,
              compact: compact,
              showTotalOnly: true,
              onTap: canceledCount > 0 ? onCanceledItemsTap : null,
            ),
            if (showDisposedCard)
              _buildMetricCard(
                title: 'Artículos Descartados',
                count: disposedCount,
                total: '$disposedCount unid.',
                totalColor: AppColors.error,
                isDark: isDark,
                compact: compact,
                showTotalOnly: true,
                onTap: disposedCount > 0 ? onDisposedItemsTap : null,
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
    required Color totalColor,
    required bool isDark,
    required bool compact,
    bool showTotalOnly = false,
    VoidCallback? onTap,
  }) {
    final padding = compact ? AppDimensions.paddingS : AppDimensions.paddingM;

    final card = Container(
      padding: EdgeInsets.all(padding),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textPrimary,
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
          SizedBox(height: compact ? 4 : 8),
          Text(
            total,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: totalColor,
            ),
          ),
          if (!showTotalOnly) ...[
            const SizedBox(height: 2),
            Text(
              '$count comprobantes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                height: 1.2,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textPrimary,
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
