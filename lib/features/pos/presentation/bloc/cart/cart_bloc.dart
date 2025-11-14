import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/cart_item.dart';
import 'package:pos_flutter_app/features/pos/domain/usecases/manage_cart_usecase.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final ManageCartUsecase manageCartUsecase;

  CartBloc({required this.manageCartUsecase}) : super(CartInitial()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<RemoveQuantityFromCart>(_onRemoveQuantityFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final currentItems = _getCurrentItems();
    final newItems = manageCartUsecase.addToCart(
        currentItems, event.product, event.quantity);
    _emitUpdatedCart(emit, newItems);
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final currentItems = _getCurrentItems();
    final newItems =
        manageCartUsecase.removeFromCart(currentItems, event.productId);
    _emitUpdatedCart(emit, newItems);
  }

  void _onRemoveQuantityFromCart(
      RemoveQuantityFromCart event, Emitter<CartState> emit) {
    final currentItems = _getCurrentItems();
    final newItems = manageCartUsecase.removeQuantityFromCart(
        currentItems, event.productId, event.quantity);
    _emitUpdatedCart(emit, newItems);
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<CartState> emit) {
    final currentItems = _getCurrentItems();
    final newItems = manageCartUsecase.updateQuantity(
      currentItems,
      event.productId,
      event.quantity,
    );
    _emitUpdatedCart(emit, newItems);
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    final newItems = manageCartUsecase.clearCart();
    _emitUpdatedCart(emit, newItems);
  }

  List<CartItem> _getCurrentItems() {
    if (state is CartLoaded) {
      return (state as CartLoaded).items;
    }
    return [];
  }

  void _emitUpdatedCart(Emitter<CartState> emit, List<CartItem> items) {
    final total = manageCartUsecase.calculateTotal(items);
    final totalItems = manageCartUsecase.getTotalItems(items);

    emit(CartLoaded(
      items: items,
      total: total,
      totalItems: totalItems,
    ));
  }

  // Método helper para obtener la cantidad de un producto en el carrito
  int getProductQuantityInCart(String productId) {
    final currentItems = _getCurrentItems();
    return manageCartUsecase.getProductQuantityInCart(currentItems, productId);
  }
}
