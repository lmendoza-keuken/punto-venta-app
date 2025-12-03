import '../entities/cart_item.dart';
import '../entities/product.dart';

class ManageCartUsecase {
  List<CartItem> addToCart(List<CartItem> currentCart, Product product,
      [int quantity = 1]) {
    final List<CartItem> newCart = List.from(currentCart);

    final existingItemIndex = newCart.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingItemIndex != -1) {
      newCart[existingItemIndex] = newCart[existingItemIndex].copyWith(
        quantity: newCart[existingItemIndex].quantity + quantity,
      );
    } else {
      newCart.add(CartItem(product: product, quantity: quantity , iva: product.iva));
    }

    return newCart;
  }


  List<CartItem> removeQuantityFromCart(
      List<CartItem> currentCart, String productId, int quantityToRemove) {
    final List<CartItem> newCart = List.from(currentCart);

    final existingItemIndex = newCart.indexWhere(
      (item) => item.product.id == productId,
    );

    if (existingItemIndex != -1) {
      final currentItem = newCart[existingItemIndex];
      final newQuantity = currentItem.quantity - quantityToRemove;

      if (newQuantity <= 0) {
        // Si la cantidad resultante es 0 o menor, eliminar el item completamente
        newCart.removeAt(existingItemIndex);
      } else {
        // Si queda cantidad, actualizar el item
        newCart[existingItemIndex] =
            currentItem.copyWith(quantity: newQuantity);
      }
    }

    return newCart;
  }


  double calculateTotal(List<CartItem> cart) {
    return cart.fold(0.0, (total, item) => total + item.totalPrice);
  }

  int getTotalItems(List<CartItem> cart) {
    return cart.fold(0, (total, item) => total + item.quantity);
  }

}
