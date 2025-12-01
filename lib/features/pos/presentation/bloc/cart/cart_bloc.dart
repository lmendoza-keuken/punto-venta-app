import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/usecases/manage_cart_usecase.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/cart_log_entry.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final ManageCartUsecase manageCartUsecase;

  CartBloc({required this.manageCartUsecase}) : super(CartInitial()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveQuantityFromCart>(_onRemoveQuantityFromCart);
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

  void _onRemoveQuantityFromCart(
      RemoveQuantityFromCart event, Emitter<CartState> emit) {
    final currentItems = _getCurrentItems();
    final newItems = manageCartUsecase.removeQuantityFromCart(
        currentItems, event.productId, event.quantity);
    final total = manageCartUsecase.calculateTotal(newItems);
    final totalItems = manageCartUsecase.getTotalItems(newItems);

    final existingProduct = currentItems.firstWhere(
      (it) => it.product.id == event.productId,
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

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
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

  String _randomId() {
    return const Uuid().v4();
  }

  int getProductQuantityInCart(String productId) {
    final currentItems = _getCurrentItems();
    final found = currentItems.firstWhere(
      (it) => it.product.id == productId,
    );
    return found.quantity;
  }
}
