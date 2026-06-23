import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';

class BarcodeSwitch extends StatelessWidget {
  const BarcodeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UiBloc, UiState>(
      builder: (context, state) {
        final uiState = state as UiLoaded;

        return Container(
          width: AppDimensions.buttonHeightm,
          height: AppDimensions.buttonHeightm,
          decoration: BoxDecoration(
            color: uiState.isBarcodeSearchEnabled
                ? AppColors.success
                : Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
            border: Border.all(
              color: uiState.isBarcodeSearchEnabled
                  ? AppColors.success
                  : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: uiState.isBarcodeSearchEnabled
                ? [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
              onTap: () {
                context.read<UiBloc>().add(ToggleBarcodeSearch());
              },
              child: Icon(
                FontAwesomeIcons.barcode,
                color: uiState.isBarcodeSearchEnabled
                    ? Colors.white
                    : AppColors.textSecondary,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}
