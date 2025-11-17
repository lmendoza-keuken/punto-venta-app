import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/manage_cart_usecase.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/cart_log_entry.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import 'dart:math';

class CartBloc extends Bloc<CartEvent, CartState> {
  final ManageCartUsecase manageCartUsecase;

  CartBloc({required this.manageCartUsecase}) : super(CartInitial()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<RemoveQuantityFromCart>(_onRemoveQuantityFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
    on<ReplaceCart>(_onReplaceCart);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final currentItems = _getCurrentItems();
    final newItems = manageCartUsecase.addToCart(
        currentItems, event.product, event.quantity);
    final total = manageCartUsecase.calculateTotal(newItems);
    final totalItems = manageCartUsecase.getTotalItems(newItems);

    final currentLog = _getCurrentLog();

    final entry = CartLogEntry(
      id: _randomId(),
      type: CartActionType.add,
      item: CartItem(product: event.product, quantity: event.quantity),
      timestamp: DateTime.now(),
    );

    final newLog = List<CartLogEntry>.from(currentLog)..add(entry);

    emit(CartLoaded(
      items: newItems,
      total: total,
      totalItems: totalItems,
      log: newLog,
    ));
  }

  void _onReplaceCart(ReplaceCart event, Emitter<CartState> emit) {
    final items = event.items;
    final log = event.log;
    final total = manageCartUsecase.calculateTotal(items);
    final totalItems = manageCartUsecase.getTotalItems(items);
    emit(CartLoaded(
        items: items, total: total, totalItems: totalItems, log: log));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final currentItems = _getCurrentItems();

    final existing = currentItems.firstWhere(
      (it) => it.product.id == event.productId,
      orElse: () => const CartItem(
          product: Product(
            codigo: 0,
            descripcion: '',
            precio: 0,
            rubro: '',
            marca: '',
            capacidad: '',
            pack: 1,
            uxb: 1,
            linea: '',
            sublinea: '',
            pesopromedio: '',
            formaventa: '',
            iva: 0,
            costo: 0,
            suspendidoVenta: 'N',
            suspendidoQuiebre: 'N',
            idProveedor: 0,
            objetivable: false,
            usaListaPrecios: true,
            oferta: false,
          ),
          quantity: 0),
    );

    final qtyToRemove = existing.quantity;

    final newItems =
        manageCartUsecase.removeFromCart(currentItems, event.productId);
    final total = manageCartUsecase.calculateTotal(newItems);
    final totalItems = manageCartUsecase.getTotalItems(newItems);

    final currentLog = _getCurrentLog();
    final entry = CartLogEntry(
      id: _randomId(),
      type: CartActionType.remove,
      item: CartItem(product: existing.product, quantity: qtyToRemove),
      timestamp: DateTime.now(),
    );
    final newLog = List<CartLogEntry>.from(currentLog)..add(entry);

    emit(CartLoaded(
      items: newItems,
      total: total,
      totalItems: totalItems,
      log: newLog,
    ));
  }

  void _onRemoveQuantityFromCart(
      RemoveQuantityFromCart event, Emitter<CartState> emit) {
    final currentItems = _getCurrentItems();
    final newItems = manageCartUsecase.removeQuantityFromCart(
        currentItems, event.productId, event.quantity);
    final total = manageCartUsecase.calculateTotal(newItems);
    final totalItems = manageCartUsecase.getTotalItems(newItems);

    final existingProduct = currentItems.firstWhere(
      (it) => it.product.id == event.productId,
      orElse: () => const CartItem(
          product: Product(
            codigo: 0,
            descripcion: '',
            precio: 0,
            rubro: '',
            marca: '',
            capacidad: '',
            pack: 1,
            uxb: 1,
            linea: '',
            sublinea: '',
            pesopromedio: '',
            formaventa: '',
            iva: 0,
            costo: 0,
            suspendidoVenta: 'N',
            suspendidoQuiebre: 'N',
            idProveedor: 0,
            objetivable: false,
            usaListaPrecios: true,
            oferta: false,
          ),
          quantity: 0),
    );

    final currentLog = _getCurrentLog();
    final entry = CartLogEntry(
      id: _randomId(),
      type: CartActionType.remove,
      item:
          CartItem(product: existingProduct.product, quantity: event.quantity),
      timestamp: DateTime.now(),
    );
    final newLog = List<CartLogEntry>.from(currentLog)..add(entry);

    emit(CartLoaded(
      items: newItems,
      total: total,
      totalItems: totalItems,
      log: newLog,
    ));
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<CartState> emit) {
    final currentItems = _getCurrentItems();
    final newItems = manageCartUsecase.updateQuantity(
        currentItems, event.productId, event.quantity);
    final total = manageCartUsecase.calculateTotal(newItems);
    final totalItems = manageCartUsecase.getTotalItems(newItems);

    final currentLog = _getCurrentLog();

    final prev = currentItems.firstWhere(
      (it) => it.product.id == event.productId,
      orElse: () => const CartItem(
          product: Product(
            codigo: 0,
            descripcion: '',
            precio: 0,
            rubro: '',
            marca: '',
            capacidad: '',
            pack: 1,
            uxb: 1,
            linea: '',
            sublinea: '',
            pesopromedio: '',
            formaventa: '',
            iva: 0,
            costo: 0,
            suspendidoVenta: 'N',
            suspendidoQuiebre: 'N',
            idProveedor: 0,
            objetivable: false,
            usaListaPrecios: true,
            oferta: false,
          ),
          quantity: 0),
    );

    final diff = event.quantity - prev.quantity;
    final List<CartLogEntry> newLog = List<CartLogEntry>.from(currentLog);
    if (diff > 0) {
      newLog.add(CartLogEntry(
        id: _randomId(),
        type: CartActionType.add,
        item: CartItem(product: prev.product, quantity: diff),
        timestamp: DateTime.now(),
      ));
    } else if (diff < 0) {
      newLog.add(CartLogEntry(
        id: _randomId(),
        type: CartActionType.remove,
        item: CartItem(product: prev.product, quantity: -diff),
        timestamp: DateTime.now(),
      ));
    }

    emit(CartLoaded(
      items: newItems,
      total: total,
      totalItems: totalItems,
      log: newLog,
    ));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    final currentLog = _getCurrentLog();
    final entry = CartLogEntry(
      id: _randomId(),
      type: CartActionType.remove,
      item: const CartItem(
          product: Product(
            codigo: 0,
            descripcion: 'VACIAR CARRITO',
            precio: 0,
            rubro: '',
            marca: '',
            capacidad: '',
            pack: 0,
            uxb: 0,
            linea: '',
            sublinea: '',
            pesopromedio: '',
            formaventa: '',
            iva: 0,
            costo: 0,
            suspendidoVenta: 'N',
            suspendidoQuiebre: 'N',
            idProveedor: 0,
            objetivable: false,
            usaListaPrecios: true,
            oferta: false,
          ),
          quantity: 0),
      timestamp: DateTime.now(),
    );

    emit(const CartLoaded(items: [], total: 0.0, totalItems: 0, log: []));
  }

  List<CartItem> _getCurrentItems() {
    if (state is CartLoaded) {
      return (state as CartLoaded).items;
    }
    return [];
  }

  List<CartLogEntry> _getCurrentLog() {
    if (state is CartLoaded) {
      return (state as CartLoaded).log;
    }
    return [];
  }

  void _emitUpdatedCart(
      Emitter<CartState> emit, List<CartItem> items, List<CartLogEntry> log) {
    final total = manageCartUsecase.calculateTotal(items);
    final totalItems = manageCartUsecase.getTotalItems(items);
    emit(CartLoaded(
        items: items, total: total, totalItems: totalItems, log: log));
  }

  String _randomId() {
    final rnd = Random();
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '-' +
        rnd.nextInt(99999).toString();
  }

  // helper method for UI usage
  int getProductQuantityInCart(String productId) {
    final currentItems = _getCurrentItems();
    final found = currentItems.firstWhere(
      (it) => it.product.id == productId,
      orElse: () => const CartItem(
          product: Product(
            codigo: 0,
            descripcion: '',
            precio: 0,
            rubro: '',
            marca: '',
            capacidad: '',
            pack: 1,
            uxb: 1,
            linea: '',
            sublinea: '',
            pesopromedio: '',
            formaventa: '',
            iva: 0,
            costo: 0,
            suspendidoVenta: 'N',
            suspendidoQuiebre: 'N',
            idProveedor: 0,
            objetivable: false,
            usaListaPrecios: true,
            oferta: false,
          ),
          quantity: 0),
    );
    return found.quantity;
  }
}
