import 'package:flutter_test/flutter_test.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';

void main() {
  test('CustomerDisplaySnapshot round-trip JSON', () {
    const original = CustomerDisplaySnapshot(
      mode: CustomerDisplayMode.cart,
      items: [
        CustomerDisplayLineItem(
          name: 'Café',
          quantityLabel: 'x2',
          lineTotal: 1500,
        ),
      ],
      subtotal: 1500,
      totalConIva: 1815,
    );

    final restored = CustomerDisplaySnapshot.fromJson(original.toJson());

    expect(restored.mode, CustomerDisplayMode.cart);
    expect(restored.items, hasLength(1));
    expect(restored.items.first.name, 'Café');
    expect(restored.totalConIva, 1815);
  });

  test('idle factory', () {
    const idle = CustomerDisplaySnapshot.idle();
    expect(idle.mode, CustomerDisplayMode.idle);
    expect(idle.items, isEmpty);
  });
}
