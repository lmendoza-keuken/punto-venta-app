import 'package:pos_flutter_app/features/pos/domain/entities/cart_item.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/saved_order.dart';
import 'package:pos_flutter_app/features/pos/domain/repositories/saved_orders_repository.dart';

class SaveOrderUsecase {
  final SavedOrdersRepository repository;

  SaveOrderUsecase(this.repository);

  Future<void> call({
    required String name,
    required List<CartItem> items,
    required double total,
    String? clientName,
  }) async {
    if (items.isEmpty) {
      throw Exception('No se puede guardar un pedido vacío');
    }

    final order = SavedOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim().isEmpty
          ? 'Pedido ${DateTime.now().day}/${DateTime.now().month}'
          : name.trim(),
      items: items,
      total: total,
      createdAt: DateTime.now(),
      clientName: clientName?.trim(),
    );

    await repository.saveOrder(order);
  }
}
