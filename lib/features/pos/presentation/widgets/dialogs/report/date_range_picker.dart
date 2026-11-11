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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < LayoutSpec.compactBreakpoint ||
            LayoutSpec.of(context).isCompact;

        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          width: double.infinity,
          child: compact ? _buildCompact() : _buildWide(),
        );
      },
    );
  }

  Widget _buildWide() {
    return Row(
      children: [
        const Text('Fecha inicio: ', style: TextStyle(color: Colors.black)),
        const SizedBox(width: AppDimensions.paddingS),
        _DateChip(
          label: DateFormat('dd/MM/yyyy').format(selectedDate),
          onTap: _selectStartDate,
        ),
        const SizedBox(width: AppDimensions.paddingM),
        const Text(
          'Fecha fin (opcional): ',
          style: TextStyle(color: Colors.black),
        ),
        const SizedBox(width: AppDimensions.paddingS),
        _DateChip(
          label: selectedEndDate != null
              ? DateFormat('dd/MM/yyyy').format(selectedEndDate!)
              : 'Sin seleccionar',
          onTap: _selectEndDate,
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
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Actualizar'),
        ),
      ],
    );
  }

  Widget _buildCompact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabeledDateField(
          label: 'Fecha inicio',
          child: _DateChip(
            label: DateFormat('dd/MM/yyyy').format(selectedDate),
            onTap: _selectStartDate,
            expanded: true,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingS),
        _LabeledDateField(
          label: 'Fecha fin (opcional)',
          child: Row(
            children: [
              Expanded(
                child: _DateChip(
                  label: selectedEndDate != null
                      ? DateFormat('dd/MM/yyyy').format(selectedEndDate!)
                      : 'Sin seleccionar',
                  onTap: _selectEndDate,
                  expanded: true,
                ),
              ),
              if (selectedEndDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => onEndDateChanged(null),
                  tooltip: 'Limpiar fecha fin',
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Actualizar'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'AR'),
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
      locale: const Locale('es', 'AR'),
    );
    if (picked != null) {
      onEndDateChanged(picked);
    }
  }
}

class _LabeledDateField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledDateField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final Future<void> Function(BuildContext context) onTap;
  final bool expanded;

  const _DateChip({
    required this.label,
    required this.onTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(context),
      child: Container(
        width: expanded ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
            const SizedBox(width: AppDimensions.paddingS),
            if (expanded)
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black),
                ),
              )
            else
              Text(label, style: const TextStyle(color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
