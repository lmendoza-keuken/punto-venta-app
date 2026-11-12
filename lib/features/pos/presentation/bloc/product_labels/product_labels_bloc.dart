import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_products_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/label_image_builder.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/base_ticket_template.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/printer_repository.dart';
import 'product_labels_event.dart';
import 'product_labels_state.dart';

class ProductLabelsBloc extends Bloc<ProductLabelsEvent, ProductLabelsState> {
  final GetProductsUsecase getProductsUsecase;
  final PriceListLocalDataSource priceListLocalDataSource;
  final PrinterRepository printerRepository;
  final PrinterLocalDataSource printerLocalDataSource;
  StreamSubscription<List<Product>>? _productsSubscription;

  ProductLabelsBloc({
    required this.getProductsUsecase,
    required this.priceListLocalDataSource,
    required this.printerRepository,
    required this.printerLocalDataSource,
  }) : super(ProductLabelsInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<ProductsUpdated>(_onProductsUpdated);
    on<ProductsErrorOccurred>(_onProductsErrorOccurred);
    on<LoadProductsByCategory>(_onLoadProductsByCategory);
    on<SearchProducts>(_onSearchProducts);
    on<ToggleProductSelection>(_onToggleProductSelection);
    on<ClearSelection>(_onClearSelection);
    on<PrintSelectedLabels>(_onPrintSelectedLabels);
    on<SelectAllVisibleProducts>(_onSelectAllVisibleProducts);
    on<SelectProductByBarcode>(_onSelectProductByBarcode);
  }

  Future<void> _onSelectAllVisibleProducts(
    SelectAllVisibleProducts event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;
    final currentState = state as ProductLabelsLoaded;
    emit(currentState.copyWith(
        selectedProducts: List<Product>.from(currentState.products)));
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductLabelsState> emit,
  ) async {
    print('DEBUG: ProductLabelsBloc._onLoadProducts() started');
    await _productsSubscription?.cancel();
    _productsSubscription = null;

    emit(ProductLabelsLoading());
    try {
      print('DEBUG: ProductLabelsBloc fetching current list...');
      int currentList = await priceListLocalDataSource.getCurrentPriceList();
      if (currentList <= 0) {
        currentList = 1;
        await priceListLocalDataSource.savePriceList(currentList);
      }
      print('DEBUG: ProductLabelsBloc current list is $currentList');

      await getProductsUsecase.updatePriceList(currentList);

      print('DEBUG: ProductLabelsBloc fetching categories...');
      final categories = await getProductsUsecase.getCategories();
      print('DEBUG: ProductLabelsBloc categories fetched: ${categories.length}');

      print('DEBUG: ProductLabelsBloc listening to getProductsUsecase() stream...');
      _productsSubscription = getProductsUsecase().listen(
        (products) {
          print('DEBUG: ProductLabelsBloc stream yielded products. Count: ${products.length}');
          add(ProductsUpdated(products: products, categories: categories));
        },
        onError: (error, stackTrace) {
          print('DEBUG: ProductLabelsBloc stream error: $error');
          add(ProductsErrorOccurred(error.toString()));
        },
      );
    } catch (e) {
      print('DEBUG: ProductLabelsBloc catch error: $e');
      emit(ProductLabelsError(e.toString()));
    }
  }

  void _onProductsUpdated(
    ProductsUpdated event,
    Emitter<ProductLabelsState> emit,
  ) {
    print('DEBUG: ProductLabelsBloc._onProductsUpdated() called. Count: ${event.products.length}');
    if (state is ProductLabelsLoaded) {
      final currentState = state as ProductLabelsLoaded;
      emit(currentState.copyWith(
        allProducts: event.products,
        categories: event.categories,
      ));
    } else {
      emit(ProductLabelsLoaded(
        allProducts: event.products,
        categories: event.categories,
        selectedProducts: const [],
      ));
    }
    print('DEBUG: ProductLabelsBloc state is now ${state.runtimeType}');
  }

  void _onProductsErrorOccurred(
    ProductsErrorOccurred event,
    Emitter<ProductLabelsState> emit,
  ) {
    print('DEBUG: ProductLabelsBloc._onProductsErrorOccurred() called. Error: ${event.error}');
    if (state is! ProductLabelsLoaded) {
      emit(ProductLabelsError(event.error));
    }
  }

  Future<void> _onLoadProductsByCategory(
    LoadProductsByCategory event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;
    final currentState = state as ProductLabelsLoaded;
    emit(currentState.copyWith(selectedCategoryId: event.categoryId));
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;
    final currentState = state as ProductLabelsLoaded;
    emit(currentState.copyWith(searchQuery: event.query));
  }

  Future<void> _onToggleProductSelection(
    ToggleProductSelection event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;

    final currentState = state as ProductLabelsLoaded;
    final selectedProducts = List<Product>.from(currentState.selectedProducts);

    if (selectedProducts.any((p) => p.id == event.product.id)) {
      selectedProducts.removeWhere((p) => p.id == event.product.id);
    } else {
      selectedProducts.add(event.product);
    }

    emit(currentState.copyWith(selectedProducts: selectedProducts));
  }

  Future<void> _onClearSelection(
    ClearSelection event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;

    final currentState = state as ProductLabelsLoaded;
    emit(currentState.copyWith(selectedProducts: []));
  }

  Future<void> _onSelectProductByBarcode(
    SelectProductByBarcode event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;
    final currentState = state as ProductLabelsLoaded;
    final code = event.barcode.trim();
    if (code.isEmpty) return;

    final match = _findProductByBarcode(currentState.allProducts, code);
    if (match == null) {
      emit(ProductLabelsBarcodeResult(
        barcode: code,
        product: null,
        previous: currentState,
      ));
      emit(currentState);
      return;
    }

    final selected = List<Product>.from(currentState.selectedProducts);
    if (!selected.any((p) => p.id == match.id)) {
      selected.add(match);
    }

    final next = currentState.copyWith(
      selectedProducts: selected,
      searchQuery: code,
    );
    emit(ProductLabelsBarcodeResult(
      barcode: code,
      product: match,
      previous: next,
    ));
    emit(next);
  }

  Product? _findProductByBarcode(List<Product> products, String code) {
    final normalized = code.trim();
    // Match exacto por barcode o id.
    for (final product in products) {
      if (product.id.toString() == normalized) return product;
      final barcodes = product.barcodes;
      if (barcodes == null) continue;
      for (final b in barcodes) {
        if (b.barcode != null && b.barcode.toString() == normalized) {
          return product;
        }
      }
    }
    return null;
  }

  Future<void> _onPrintSelectedLabels(
    PrintSelectedLabels event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;

    final currentState = state as ProductLabelsLoaded;
    final selectedProducts = currentState.selectedProducts;

    if (selectedProducts.isEmpty) {
      emit(const ProductLabelsPrintError(
          'No hay productos seleccionados para imprimir'));
      emit(currentState);
      return;
    }

    emit(ProductLabelsPrinting(selectedProducts));

    try {
      final config = await printerLocalDataSource.getPrinterConfig();

      // Misma regla que tickets: auto/builtin → PTA; network → IP.
      if (config.outputMode == PrinterOutputMode.network &&
          config.ip.trim().isEmpty) {
        throw Exception(
          'No hay una dirección IP configurada para la impresora',
        );
      }

      final connected = await printerRepository.connect(config);
      if (!connected) {
        throw Exception('No se pudo conectar con la impresora');
      }

      final forPta = printerRepository.isUsingBuiltin;
      // IP: tamaño de config. PTA: layout propio 384×240 (no reusa el de red).
      final labelSize = forPta
          ? LabelImageBuilder.ptaWidth
          : (config.labelType == 0 ? 8 * 72 : 8 * 52);

      for (final product in selectedProducts) {
        final imageBytes = await LabelImageBuilder.buildProductLabelImage(
          product,
          forPta: forPta,
        );

        // PTA: corta entre etiquetas (paperCut). IP: feed + cut ESC/POS.
        final commands = forPta
            ? [
                TicketCommand.image(imageBytes, labelSize),
                TicketCommand.cutPaper(walkLines: 14),
              ]
            : [
                TicketCommand.image(imageBytes, labelSize),
                TicketCommand.feedLine(),
                TicketCommand.cutPaper(),
              ];

        final success = await printerRepository.printCommands(commands);
        if (!success) {
          throw Exception('Error al imprimir etiqueta de ${product.name}');
        }
      }

      await printerRepository.disconnect();

      emit(ProductLabelsPrintSuccess(selectedProducts.length));

      emit(currentState.copyWith(selectedProducts: []));
    } catch (e) {
      try {
        await printerRepository.disconnect();
      } catch (_) {}

      emit(ProductLabelsPrintError(e.toString()));
      emit(currentState);
    }
  }

  @override
  Future<void> close() {
    _productsSubscription?.cancel();
    return super.close();
  }
}
