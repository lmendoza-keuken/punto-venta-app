import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/data/models/category_model.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/common/barcode_scanner_page.dart';

class ProductLabelsSearchBar extends StatefulWidget {
  const ProductLabelsSearchBar({super.key});

  @override
  State<ProductLabelsSearchBar> createState() => _ProductLabelsSearchBarState();
}

class _ProductLabelsSearchBarState extends State<ProductLabelsSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;

  static bool get _isAndroidCameraAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openBarcodeScanner() async {
    final code = await BarcodeScannerPage.open(context);
    if (!mounted || code == null || code.trim().isEmpty) return;

    _searchController.text = code.trim();
    context.read<ProductLabelsBloc>().add(SelectProductByBarcode(code.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductLabelsBloc, ProductLabelsState>(
      listenWhen: (previous, current) => current is ProductLabelsBarcodeResult,
      listener: (context, state) {
        if (state is! ProductLabelsBarcodeResult) return;
        final messenger = ScaffoldMessenger.of(context);
        if (state.found) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Producto seleccionado: ${state.product!.name}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('No se encontró producto con código ${state.barcode}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<ProductLabelsBloc, ProductLabelsState>(
        builder: (context, state) {
          final isLoaded = state is ProductLabelsLoaded;
          final categories =
              isLoaded ? state.categories : const <CategoryModel>[];
          final compact = LayoutSpec.of(context).isCompact;

          // Sync search text when barcode selection updates the query.
          if (isLoaded &&
              state.searchQuery != _searchController.text &&
              state.searchQuery.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_searchController.text != state.searchQuery) {
                _searchController.text = state.searchQuery;
                _searchController.selection = TextSelection.collapsed(
                  offset: _searchController.text.length,
                );
              }
            });
          }

          final search = _buildSearchField(isLoaded);
          final category = _buildCategoryDropdown(isLoaded, categories);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: AppDimensions.paddingS),
                category,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 16),
              SizedBox(
                width: 250,
                child: category,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField(bool enabled) {
    final clearButton = _searchController.text.isNotEmpty && enabled
        ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<ProductLabelsBloc>().add(const SearchProducts(''));
              setState(() {});
            },
          )
        : null;

    final scanButton = _isAndroidCameraAvailable
        ? IconButton(
            tooltip: 'Escanear código de barras',
            onPressed: enabled ? _openBarcodeScanner : null,
            icon: const Icon(Icons.qr_code_scanner),
            color: AppColors.primary,
          )
        : null;

    return TextField(
      controller: _searchController,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: 'Buscar productos...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (clearButton != null) clearButton,
            if (scanButton != null) scanButton,
          ],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        setState(() {});
        context.read<ProductLabelsBloc>().add(SearchProducts(value));
      },
    );
  }

  Widget _buildCategoryDropdown(bool enabled, List<CategoryModel> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Categoría',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text(
            'Todas las categorías',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...categories
            .where((cat) => (cat.id ?? '').isNotEmpty)
            .map((category) {
          return DropdownMenuItem(
            value: category.id,
            child: Text(
              category.description ?? '',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: enabled
          ? (value) {
              setState(() {
                _selectedCategoryId = value;
              });
              if (value == null) {
                context.read<ProductLabelsBloc>().add(const LoadProducts());
              } else {
                context
                    .read<ProductLabelsBloc>()
                    .add(LoadProductsByCategory(value));
              }
            }
          : null,
    );
  }
}
