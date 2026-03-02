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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      child: Row(
        children: [
          Expanded(
              child: _buildSummaryCard(
                  context,
                  'Total Ventas',
                  (summary['total_sales'] as double).formatToCurrency(),
                  Icons.attach_money,
                  AppColors.success)),
          Expanded(
              child: _buildSummaryCard(
                  context,
                  'Órdenes',
                  '${summary['total_orders']}',
                  Icons.receipt,
                  AppColors.primary)),
          Expanded(
              child: _buildSummaryCard(
                  context,
                  'Artículos',
                  '${summary['total_items']}',
                  Icons.inventory,
                  AppColors.warning)),
          Expanded(
              child: _buildSummaryCard(
                  context,
                  'IVA Total',
                  (summary['total_tax'] as double).formatToCurrency(),
                  Icons.percent,
                  AppColors.info)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
