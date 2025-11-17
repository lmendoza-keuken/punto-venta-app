import 'package:pos_flutter_app/features/pos/domain/entities/cart_log_entry.dart';

import '../entities/completed_order.dart';
import '../entities/cart_item.dart';
import '../repositories/completed_orders_repository.dart';

class CompleteOrderUsecase {
  final CompletedOrdersRepository repository;

  CompleteOrderUsecase(this.repository);

  Future<CompletedOrder> call({
    required List<CartItem> items,
    required List<CartLogEntry> logItems,
    required double total,
    String? clientName,
    required String cashierName,
    String paymentMethod = 'Efectivo',
  }) async {
    if (items.isEmpty) {
      throw Exception('No se puede completar una orden vacía');
    }

    final now = DateTime.now();
    final orderNumber = _generateOrderNumber(now);
    final totalItems = items.fold(0, (sum, item) => sum + item.quantity);
    final totalTax = total * 0.21; // IVA del 21%

    final order = CompletedOrder(
      id: now.millisecondsSinceEpoch.toString(),
      orderNumber: orderNumber,
      items: items,
      logs: logItems,
      total: total,
      completedAt: now,
      clientName: clientName?.trim(),
      cashierName: cashierName,
      paymentMethod: paymentMethod,
      totalTax: totalTax,
      totalItems: totalItems,
    );

    await repository.saveCompletedOrder(order);
    return order;
  }

  String _generateOrderNumber(DateTime date) {
    return 'ORD-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}-${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}';
  }
}
