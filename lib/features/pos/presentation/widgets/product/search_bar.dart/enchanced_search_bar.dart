import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/search_bar.dart/barcode_switch.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/search_bar.dart/delete_button.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/search_bar.dart/quantity_field.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/search_bar.dart/search_field.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
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

  //TODO: MOVER FUNCIONALIDADES FUERA DEL WIDGET
  //agregar producto por peso
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
    double? weightKg;
    double? pricePerKg;
    double? calculatedUnitPrice;

    if (prodState is ProductLoaded) {
      if (isBarcodeMode) {
        //separarlo a una funcion aparte
        if (code.length == 13 &&
            (code.startsWith('20') || code.startsWith('21'))) {
          final weightString = code.substring(7, 12);
          final codeString = code.substring(2, 7);
          final weightInt = int.tryParse(weightString) ?? 0;
          weightKg = weightInt / 1000.0;

          found = prodState.products.cast<Product?>().firstWhere(
            (p) {
              final pcode = p?.code ?? '';
              if (pcode == codeString) return true;
              try {
                final idFromCode = int.parse(codeString);
                if (p?.id == idFromCode) return true;
              } catch (_) {}
              if (pcode.endsWith(codeString)) return true;
              return false;
            },
            orElse: () => null,
          );

          if (found != null) {
            final netWeight = found.netWeight;
            final priceNetWeight = netWeight > 0 ? found.precio ?? 0.0 : 0.0;

            // Falta el fraccionado
            calculatedUnitPrice = (priceNetWeight *
                weightKg /
                (netWeight) *
                (double.tryParse(found.fractional.toString()) ?? 1));
          }
        } else {
          for (var product in prodState.products) {
            if (product.barcodes != null) {
              for (var barcode in product.barcodes!) {
                if (barcode.barcode.toString() == code) {
                  found = product;
                  matchedBarcode = barcode;
                  break;
                }
              }
              if (found != null) break;
            }
          }
        }
      } else {
        try {
          final productCode = int.parse(code);
          found = prodState.products.cast<Product?>().firstWhere(
                (p) => p!.id == productCode,
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
      finalQuantity = qty * (matchedBarcode.units ?? 1);

      String tipoVentaMsg = '';
      switch (matchedBarcode.type) {
        case 1:
          tipoVentaMsg = 'Unidad';
          break;
        case 2:
          tipoVentaMsg = 'Pack (${matchedBarcode.units} unidades)';
          break;
        case 3:
          tipoVentaMsg = 'Bulto (${matchedBarcode.units} unidades)';
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
      final quantityInCart =
          cartBloc.getProductQuantityInCart(found.id.toString());
      if (weightKg != null && calculatedUnitPrice != null) {
        cartBloc.add(RemoveQuantityFromCart(
          found.id.toString(),
          quantityInCart,
          isWeighted: true,
          weightKg: weightKg,
          pricePerKg: calculatedUnitPrice,
        ));
      } else {
        cartBloc
            .add(RemoveQuantityFromCart(found.id.toString(), quantityInCart));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${found.name} eliminado del carrito'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      if (weightKg != null && calculatedUnitPrice != null) {
        cartBloc.add(AddToCart(
          found,
          quantity: finalQuantity,
          isWeighted: true,
          weightKg: weightKg,
          pricePerKg: calculatedUnitPrice,
        ));
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
          //TODO: CAMBIAR PARA QUE SEA SOLO PASAR UN WIDGET
          child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
        );
      },
    );
  }

  Widget _buildFullLayout() {
    return Row(
      children: [
        // Campo de cantidad (izquierda)
        const QuantityField(),
        const SizedBox(width: AppDimensions.paddingM),

        // Campo de búsqueda (centro)
        Expanded(
            child: SearchField(
          controller: widget.searchController,
          autofocus: widget.autofocus,
          onSearchChanged: widget.onSearchChanged,
          onClearSearch: widget.onClearSearch,
          onSubmitted: _handleCodeInput,
        )),
        const SizedBox(width: AppDimensions.paddingM),

        // Switch de código de barras
        const BarcodeSwitch(),
        const SizedBox(width: AppDimensions.paddingM),

        // Botón de eliminar (derecha)
        const DeleteButton(),
      ],
    );
  }

  //TODO SACAR FUERA FUNCIONALIDADES A UN WIDGET SEPARADO (responsive)
  Widget _buildCompactLayout() {
    return Column(
      children: [
        // Primera fila: Cantidad, switch y eliminar
        Row(
          children: [
            const QuantityField(),
            const SizedBox(width: AppDimensions.paddingS),
            const BarcodeSwitch(),
            const Spacer(),
            const DeleteButton(),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingS),

        // Segunda fila: Búsqueda
        SearchField(
          controller: widget.searchController,
          autofocus: widget.autofocus,
          onSearchChanged: widget.onSearchChanged,
          onClearSearch: widget.onClearSearch,
          onSubmitted: _handleCodeInput,
        ),
      ],
    );
  }
}
