import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/actiont_buttons_layout.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onReportPressed;
  final VoidCallback onSaveOrderPressed;
  final VoidCallback onResumePressed;
  final VoidCallback onSelectClientPressed;
  final VoidCallback onAddClientPressed;
  final VoidCallback onConfirmPressed;
  final bool isCompact;

  const ActionButtons({
    super.key,
    required this.onReportPressed,
    required this.onSaveOrderPressed,
    required this.onResumePressed,
    required this.onSelectClientPressed,
    required this.onAddClientPressed,
    required this.onConfirmPressed,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ActionButtonsLayout(
        onReportPressed: onReportPressed,
        onSaveOrderPressed: onSaveOrderPressed,
        onResumePressed: onResumePressed,
        onSelectClientPressed: onSelectClientPressed,
        onAddClientPressed: onAddClientPressed,
        onConfirmPressed: onConfirmPressed,
        isCompact: isCompact,
      ),
    );
  }
}
