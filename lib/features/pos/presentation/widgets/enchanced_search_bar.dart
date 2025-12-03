import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

class EnhancedSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;

  final bool autofocus;

  const EnhancedSearchBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.autofocus = false,
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

  Future<void> _handleCodeInput(String value) async {
    final code = value.trim();
    if (code.isEmpty) return;

    final uiState = context.read<UiBloc>().state;
    int qty = 1;
    bool isDeleteMode = false;
    bool isBarcodeMode = false;

    if (uiState is UiLoaded) {
      qty = uiState.selectedQuantity;
      isDeleteMode = uiState.isDeleteMode;
      isBarcodeMode = uiState.isBarcodeSearchEnabled;
    }

    final productBloc = context.read<ProductBloc>();
    final prodState = productBloc.state;
    Product? found;
    BarcodeModel? matchedBarcode;

    if (prodState is ProductLoaded) {
      if (isBarcodeMode) {
        for (var product in prodState.products) {
          if (product.barcodes != null) {
            for (var barcode in product.barcodes!) {
              if (barcode.codigoBarra.toString() == code) {
                found = product;
                matchedBarcode = barcode;
                break;
              }
            }
            if (found != null) break;
          }
        }
      } else {
        try {
          final productCode = int.parse(code);
          found = prodState.products.cast<Product?>().firstWhere(
                (p) => p!.codigo == productCode,
                orElse: () => null,
              );
        } catch (_) {
          found = null;
        }
      }
    }

    if (found == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto no encontrado: $code'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      widget.searchController.clear();
      return;
    }

    int finalQuantity = qty;
    if (matchedBarcode != null) {
      finalQuantity = qty * matchedBarcode.unidades;

      String tipoVentaMsg = '';
      switch (matchedBarcode.tipoVenta) {
        case 1:
          tipoVentaMsg = 'Unidad';
          break;
        case 2:
          tipoVentaMsg = 'Pack (${matchedBarcode.unidades} unidades)';
          break;
        case 3:
          tipoVentaMsg = 'Bulto (${matchedBarcode.unidades} unidades)';
          break;
      }

      if (tipoVentaMsg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tipo de venta: $tipoVentaMsg'),
            backgroundColor: AppColors.info,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }

    final cartBloc = context.read<CartBloc>();
    if (isDeleteMode) {
      final quantityInCart = cartBloc.getProductQuantityInCart(found.id);
      cartBloc.add(RemoveQuantityFromCart(found.code, quantityInCart));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${found.name} eliminado del carrito'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      cartBloc.add(AddToCart(found, quantity: finalQuantity));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$finalQuantity x ${found.name} agregado'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    widget.searchController.clear();
    widget.onClearSearch();
    context.read<UiBloc>().add(ResetQuantity());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.all(
              isCompact ? AppDimensions.paddingS : AppDimensions.paddingM),
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

        // Switch de código de barras
        _buildBarcodeSwitch(),
        const SizedBox(width: AppDimensions.paddingM),

        // Botón de eliminar (derecha)
        _buildDeleteButton(),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      children: [
        // Primera fila: Cantidad, switch y eliminar
        Row(
          children: [
            _buildQuantityField(),
            const SizedBox(width: AppDimensions.paddingS),
            _buildBarcodeSwitch(),
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

  Widget _buildBarcodeSwitch() {
    return BlocBuilder<UiBloc, UiState>(
      builder: (context, state) {
        final uiState = state as UiLoaded;

        return Container(
          width: 56,
          height: 56,
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
                      color: AppColors.success.withOpacity(0.3),
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

  Widget _buildQuantityField() {
    return BlocBuilder<UiBloc, UiState>(
      builder: (context, state) {
        // final uiState = state as UiLoaded;

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
    return BlocBuilder<UiBloc, UiState>(
      builder: (context, state) {
        final uiState = state as UiLoaded;

        return TextField(
          controller: widget.searchController,
          autofocus: widget.autofocus,
          decoration: InputDecoration(
            hintText: uiState.isBarcodeSearchEnabled
                ? AppStrings.searchBarCodeHint
                : AppStrings.searchHint,
            prefixIcon: Icon(
              uiState.isBarcodeSearchEnabled
                  ? FontAwesomeIcons.barcode
                  : Icons.search,
              color: AppColors.primary,
            ),
            suffixIcon: widget.searchController.text.isNotEmpty
                ? IconButton(
                    icon:
                        const Icon(Icons.clear, color: AppColors.textSecondary),
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
          onChanged:
              uiState.isBarcodeSearchEnabled ? null : widget.onSearchChanged,
          onSubmitted: (value) {
            _handleCodeInput(value);
          },
        );
      },
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
