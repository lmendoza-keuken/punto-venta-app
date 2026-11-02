import 'package:flutter_test/flutter_test.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';

Product _product({required double price, required double vat}) {
  return Product(
    id: 3,
    description: 'GASEOSA',
    stock: 10,
    supplierId: 1,
    vat: vat,
    internalTax: 0,
    isWeighted: 'N',
    netWeight: 0,
    categoryId: '1',
    suspendedForSale: 'N',
    suspendedForPurchase: 'N',
    isActive: 'Y',
    categoryDescription: 'ALMACEN',
    price: price,
    isOnSale: false,
  );
}

void main() {
  test('unit price includes IVA like POS log', () {
    // 621.4876 * 1.21 ≈ 752
    final unit = customerDisplayUnitPriceWithTax(
      _product(price: 621.4876033057851, vat: 21),
    );
    expect(unit, closeTo(752.0, 0.01));
  });

  test('fromCartLoaded maps line items with IVA', () {
    final product = _product(price: 621.4876033057851, vat: 21);
    final cart = CartLoaded(
      items: [CartItem(product: product, quantity: 4, iva: 21)],
      total: 2485.95,
      totalItems: 4,
      log: const [],
      subtotal: 2485.95,
      totalIva: 522.05,
      internalTax: 0,
      totalConIva: 3008.0,
    );

    final snap = CustomerDisplaySnapshot.fromCartLoaded(cart);
    expect(snap.items, hasLength(1));
    expect(snap.items.first.unitPrice, closeTo(752.0, 0.01));
    expect(snap.items.first.lineTotal, closeTo(3008.0, 0.05));
  });

  test('CustomerDisplaySnapshot round-trip JSON', () {
    const original = CustomerDisplaySnapshot(
      mode: CustomerDisplayMode.payment,
      items: [
        CustomerDisplayLineItem(
          name: 'Café',
          quantityLabel: 'x2',
          unitPrice: 750,
          lineTotal: 1500,
        ),
      ],
      subtotal: 1500,
      totalConIva: 1815,
      qrLabel: 'Mercado Pago',
      qrPayload: 'https://mpago.la/demo',
      isProcessing: true,
    );

    final restored = CustomerDisplaySnapshot.fromJson(original.toJson());

    expect(restored.mode, CustomerDisplayMode.payment);
    expect(restored.items, hasLength(1));
    expect(restored.items.first.name, 'Café');
    expect(restored.items.first.unitPrice, 750);
    expect(restored.totalConIva, 1815);
    expect(restored.qrLabel, 'Mercado Pago');
    expect(restored.qrPayload, 'https://mpago.la/demo');
    expect(restored.isProcessing, isTrue);
  });

  test('idle and advertising factories', () {
    expect(const CustomerDisplaySnapshot.idle().mode, CustomerDisplayMode.idle);
    expect(
      const CustomerDisplaySnapshot.advertising().mode,
      CustomerDisplayMode.advertising,
    );
  });

  test('lastProduct round-trip JSON', () {
    const last = CustomerDisplayLastProduct(
      entryId: 'e1',
      productId: 2,
      name: 'Gaseosa',
      imageUrl: 'https://example.com/img.png',
      isAdd: true,
      isWeighted: false,
      quantityLabel: '+1',
      unitPrice: 1817,
      lineTotal: 1817,
    );
    const snap = CustomerDisplaySnapshot(
      mode: CustomerDisplayMode.cart,
      lastProduct: last,
      totalConIva: 1817,
    );
    final restored = CustomerDisplaySnapshot.fromJson(snap.toJson());
    expect(restored.lastProduct?.name, 'Gaseosa');
    expect(restored.lastProduct?.imageUrl, 'https://example.com/img.png');
    expect(restored.lastProduct?.isAdd, isTrue);
  });
}
