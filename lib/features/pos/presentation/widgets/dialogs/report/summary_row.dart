import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';

class SummaryRow extends StatelessWidget {
  final Map<String, dynamic> summary;

  const SummaryRow({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryMetric(
        title: 'Total Ventas',
        value: (summary['total_sales'] as double).formatToCurrency(),
        color: AppColors.success,
      ),
      _SummaryMetric(
        title: 'Tickets',
        value: '${summary['total_orders']}',
        color: AppColors.primary,
      ),
      _SummaryMetric(
        title: 'Artículos',
        value: '${summary['total_items']}',
        color: AppColors.warning,
      ),
      _SummaryMetric(
        title: 'IVA Total',
        value: (summary['total_tax'] as double).formatToCurrency(),
        color: AppColors.info,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < LayoutSpec.compactBreakpoint;

          if (compact) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppDimensions.paddingS,
                crossAxisSpacing: AppDimensions.paddingS,
                mainAxisExtent: 78,
              ),
              itemBuilder: (context, index) =>
                  _buildSummaryCard(context, cards[index], compact: true),
            );
          }

          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: AppDimensions.paddingS),
                Expanded(
                  child: _buildSummaryCard(context, cards[i]),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    _SummaryMetric metric, {
    bool compact = false,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingS,
          vertical: compact ? AppDimensions.paddingS : AppDimensions.paddingS,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              metric.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                metric.value,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: metric.color,
                      fontSize: 18,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric {
  final String title;
  final String value;
  final Color color;

  const _SummaryMetric({
    required this.title,
    required this.value,
    required this.color,
  });
}
