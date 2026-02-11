import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/core/widgets/custom_button.dart';

class ActionButtonsLayout extends StatelessWidget {
  final VoidCallback onReportPressed;
  final VoidCallback onSaveOrderPressed;
  final VoidCallback onResumePressed;
  final VoidCallback onSelectClientPressed;
  final VoidCallback onAddClientPressed;
  final VoidCallback onConfirmPressed;
  final bool isCompact;

  const ActionButtonsLayout({
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
    return isCompact ? _buildCompactLayout() : _buildFullLayout();
  }

  Widget _buildFullLayout() {
    return Row(
      children: [
        // Botones de la izquierda
        Expanded(
          child: Row(
            children: [
              CustomButton(
                text: AppStrings.report,
                onPressed: onReportPressed,
                backgroundColor: AppColors.reportButton,
                icon: Icons.assessment,
                iconColor: Colors.white,
                height: AppDimensions.buttonHeightS,
              ),
              const SizedBox(width: AppDimensions.paddingS),
              CustomButton(
                text: AppStrings.saveOrder,
                onPressed: onSaveOrderPressed,
                backgroundColor: AppColors.saveButton,
                icon: Icons.save,
                iconColor: Colors.white,
                height: AppDimensions.buttonHeightS,
              ),
              const SizedBox(width: AppDimensions.paddingS),
              CustomButton(
                text: AppStrings.resume,
                onPressed: onResumePressed,
                backgroundColor: AppColors.resumeButton,
                icon: Icons.summarize,
                iconColor: Colors.white,
                height: AppDimensions.buttonHeightS,
              ),
            ],
          ),
        ),

        // Botones de la derecha
        Row(
          children: [
            CustomButton(
              text: AppStrings.selectClient,
              onPressed: onSelectClientPressed,
              backgroundColor: AppColors.selectClientButton,
              icon: Icons.person_search,
              iconColor: Colors.white,
              height: AppDimensions.buttonHeightS,
            ),
            const SizedBox(width: AppDimensions.paddingS),
            CustomButton(
              text: AppStrings.addClient,
              onPressed: onAddClientPressed,
              backgroundColor: AppColors.addClientButton,
              icon: Icons.person_add,
              iconColor: Colors.white,
              height: AppDimensions.buttonHeightS,
            ),
            const SizedBox(width: AppDimensions.paddingS),
            CustomButton(
              text: AppStrings.confirm,
              onPressed: onConfirmPressed,
              backgroundColor: AppColors.confirmButton,
              icon: Icons.payment,
              iconColor: Colors.white,
              height: AppDimensions.buttonHeightS,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      children: [
        // Primera fila
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: AppStrings.report,
                onPressed: onReportPressed,
                backgroundColor: AppColors.reportButton,
                icon: Icons.assessment,
                iconColor: Colors.white,
                height: AppDimensions.buttonHeightS,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: CustomButton(
                text: AppStrings.saveOrder,
                onPressed: onSaveOrderPressed,
                backgroundColor: AppColors.saveButton,
                icon: Icons.save,
                iconColor: Colors.white,
                height: AppDimensions.buttonHeightS,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: CustomButton(
                text: AppStrings.resume,
                onPressed: onResumePressed,
                backgroundColor: AppColors.resumeButton,
                icon: Icons.summarize,
                iconColor: Colors.white,
                height: AppDimensions.buttonHeightS,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingS),

        // Segunda fila
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: AppStrings.selectClient,
                onPressed: onSelectClientPressed,
                backgroundColor: AppColors.selectClientButton,
                icon: Icons.person_search,
                iconColor: Colors.white,
                height: AppDimensions.buttonHeightS,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: CustomButton(
                text: AppStrings.addClient,
                onPressed: onAddClientPressed,
                backgroundColor: AppColors.addClientButton,
                icon: Icons.person_add,
                iconColor: Colors.white,
                height: AppDimensions.buttonHeightS,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: CustomButton(
                text: AppStrings.confirm,
                onPressed: onConfirmPressed,
                backgroundColor: AppColors.confirmButton,
                icon: Icons.payment,
                iconColor: Colors.white,
                height: AppDimensions.buttonHeightS,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
