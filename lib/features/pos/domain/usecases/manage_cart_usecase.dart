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
      newCart.add(CartItem(product: product, quantity: quantity));
    }

    return newCart;
  }

  List<CartItem> removeFromCart(List<CartItem> currentCart, String productId) {
    return currentCart.where((item) => item.product.id != productId).toList();
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

  List<CartItem> updateQuantity(
    List<CartItem> currentCart,
    String productId,
    int quantity,
  ) {
    if (quantity <= 0) {
      return removeFromCart(currentCart, productId);
    }

    final List<CartItem> newCart = currentCart.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    return newCart;
  }

  List<CartItem> clearCart() {
    return [];
  }

  double calculateTotal(List<CartItem> cart) {
    return cart.fold(0.0, (total, item) => total + item.totalPrice);
  }

  int getTotalItems(List<CartItem> cart) {
    return cart.fold(0, (total, item) => total + item.quantity);
  }

  // Método para verificar si un producto está en el carrito y obtener su cantidad
  int getProductQuantityInCart(List<CartItem> cart, String productId) {
    final item = cart.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => const CartItem(
          product: Product(
            codigo: 0,
            descripcion: '',
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
            suspendidoVenta: '',
            suspendidoQuiebre: '',
            idProveedor: 0,
            objetivable: false,
            usaListaPrecios: false,
            oferta: false,
          ),
          quantity: 0),
    );
    return item.quantity;
  }
}
