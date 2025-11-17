import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_flutter_app/core/constants/app_colors.dart';
import 'package:pos_flutter_app/core/constants/app_dimensions.dart';
import 'package:pos_flutter_app/core/constants/app_string.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/ui/ui_state.dart';

class EnhancedSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;

  const EnhancedSearchBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar> {
  final TextEditingController _quantityController =
      TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el estado UI para resetear la cantidad
    context.read<UiBloc>().stream.listen((state) {
      if (state is UiLoaded && state.selectedQuantity == 1) {
        if (_quantityController.text != '1') {
          _quantityController.text = '1';
        }
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
        );
      },
    );
  }

  Widget _buildFullLayout() {
    return Row(
      children: [
        // Campo de cantidad (izquierda)
        _buildQuantityField(),
        const SizedBox(width: AppDimensions.paddingM),

        // Campo de búsqueda (centro)
        Expanded(child: _buildSearchField()),
        const SizedBox(width: AppDimensions.paddingM),

        // Botón de eliminar (derecha)
        _buildDeleteButton(),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      children: [
        // Primera fila: Cantidad y eliminar
        Row(
          children: [
            _buildQuantityField(),
            const Spacer(),
            _buildDeleteButton(),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingS),

        // Segunda fila: Búsqueda
        _buildSearchField(),
      ],
    );
  }

  Widget _buildQuantityField() {
    return BlocBuilder<UiBloc, UiState>(
      builder: (context, state) {
        return Container(
          width: 80,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Container(
                height: 20,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.borderRadiusM),
                    topRight: Radius.circular(AppDimensions.borderRadiusM),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Cant.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    final quantity = int.tryParse(value) ?? 1;
                    if (quantity > 0) {
                      context.read<UiBloc>().add(SetQuantity(quantity));
                    } else {
                      _quantityController.text = '1';
                      context.read<UiBloc>().add(const SetQuantity(1));
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: widget.searchController,
      decoration: InputDecoration(
        hintText: AppStrings.searchHint,
        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
        suffixIcon: widget.searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: widget.onClearSearch,
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
      onChanged: widget.onSearchChanged,
    );
  }

  Widget _buildDeleteButton() {
    return BlocBuilder<UiBloc, UiState>(
      builder: (context, state) {
        final uiState = state as UiLoaded;

        return Container(
          width: 56,
          height: 56,
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
                      color: AppColors.error.withOpacity(0.3),
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
