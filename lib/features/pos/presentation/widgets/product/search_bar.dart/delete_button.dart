import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';

class DeleteButton extends StatelessWidget {
  const DeleteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UiBloc, UiState>(
      builder: (context, state) {
        final uiState = state as UiLoaded;

        return Container(
          width: AppDimensions.buttonHeightm,
          height: AppDimensions.buttonHeightm,
          decoration: BoxDecoration(
            color: uiState.isDeleteMode ? AppColors.error : Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
            border: Border.all(
              color:
                  uiState.isDeleteMode ? AppColors.error : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: uiState.isDeleteMode
                ? [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.3),
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
                context.read<UiBloc>().add(ToggleDeleteMode());
              },
              child: Icon(
                Icons.delete,
                color: uiState.isDeleteMode
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
