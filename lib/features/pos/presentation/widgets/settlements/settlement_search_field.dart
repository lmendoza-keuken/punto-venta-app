import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';

class SettlementSearchField extends StatelessWidget {
  final TextEditingController controller;

  const SettlementSearchField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextField(
            controller: controller,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar cobrador por nombre o ID...',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.6)
                    : AppColors.textHint,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => controller.clear(),
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    )
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.darkCard : Colors.white,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
                borderSide: isDark
                    ? const BorderSide(color: AppColors.darkDivider)
                    : BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
                borderSide: isDark
                    ? const BorderSide(color: AppColors.darkDivider)
                    : BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
            ),
          );
        },
      ),
    );
  }
}
