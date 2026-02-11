import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function(String) onSubmitted;

  const SearchField({
    super.key,
    required this.controller,
    required this.autofocus,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UiBloc, UiState>(
      builder: (context, state) {
        final uiState = state as UiLoaded;

        return SizedBox(
          height: AppDimensions.buttonHeightm,
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              hintText: uiState.isBarcodeSearchEnabled
                  ? AppStrings.searchBarCodeHint
                  : AppStrings.searchHint,
              prefixIcon: Icon(
                uiState.isBarcodeSearchEnabled
                    ? FontAwesomeIcons.barcode
                    : Icons.search,
                color: AppColors.primary,
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon:
                          const Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: onClearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: uiState.isBarcodeSearchEnabled ? null : onSearchChanged,
            onSubmitted: (value) => onSubmitted(value),
          ),
        );
      },
    );
  }
}