import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';

class SettlementDatePickerBar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const SettlementDatePickerBar({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'AR'),
    );
    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final isToday = selectedDate.day == today.day &&
        selectedDate.month == today.month &&
        selectedDate.year == today.year;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: Card(
        elevation: 0,
        color: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
          side: isDark
              ? const BorderSide(color: AppColors.darkDivider)
              : BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Chevron Left (Day Before)
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  onDateChanged(selectedDate.subtract(const Duration(days: 1)));
                },
                tooltip: 'Día anterior',
              ),

              // Date display and calendar button
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.paddingS,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chevron Right (Day After)
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: isToday
                    ? null
                    : () {
                        onDateChanged(selectedDate.add(const Duration(days: 1)));
                      },
                tooltip: 'Día siguiente',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
