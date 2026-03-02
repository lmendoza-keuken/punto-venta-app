import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';

class DateRangePicker extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime? selectedEndDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final VoidCallback onUpdate;

  const DateRangePicker({
    super.key,
    required this.selectedDate,
    this.selectedEndDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Fecha inicio: '),
              const SizedBox(width: AppDimensions.paddingS),
              InkWell(
                onTap: () => _selectStartDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.paddingS,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              const Text('Fecha fin (opcional): '),
              const SizedBox(width: AppDimensions.paddingS),
              InkWell(
                onTap: () => _selectEndDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.paddingS,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(selectedEndDate != null
                          ? DateFormat('dd/MM/yyyy').format(selectedEndDate!)
                          : 'Sin seleccionar'),
                    ],
                  ),
                ),
              ),
              if (selectedEndDate != null) ...[
                const SizedBox(width: AppDimensions.paddingS),
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => onEndDateChanged(null),
                  tooltip: 'Limpiar fecha fin',
                ),
              ],
              const SizedBox(width: AppDimensions.paddingM),
              ElevatedButton(
                onPressed: onUpdate,
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      onStartDateChanged(picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedEndDate ?? selectedDate,
      firstDate: selectedDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      onEndDateChanged(picked);
    }
  }
}
