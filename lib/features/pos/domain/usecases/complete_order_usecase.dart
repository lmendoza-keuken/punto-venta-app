import 'package:punto_venta_app/core/constants/ticket_template_types.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';

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
    PaymentMethod? paymentMethod,
    bool showSubtotalAndTax = false,
    bool showPricesWithTax = true,
    double? receivedAmount,
    double? change,
    TicketTemplateType templateType = TicketTemplateType.standard,
  }) async {
    if (items.isEmpty) {
      throw Exception('No se puede completar una orden vacía');
    }

    final now = DateTime.now();
    
    // GENERA NUMERO DE ORDEN ()
    final orderNumber = _generateOrderNumber(now);
    final totalItems = items.fold(0, (sum, item) => sum + item.quantity);

    double totalTax = 0;
    for (var item in items) {
      final precio = item.product.price ?? 0;
      final cantidad = item.quantity;
      final tasaIva = item.product.vat / 100;

      final precioTotal = precio * cantidad;
      final ivaArticulo = precioTotal * tasaIva;

      totalTax += ivaArticulo;
    }

    final order = CompletedOrder(
      // deberia ser el id del ticket.
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
      showSubtotalAndTax: showSubtotalAndTax,
      showPricesWithTax: showPricesWithTax,
      receivedAmount: receivedAmount,
      change: change,
      templateType: templateType,
    );

    await repository.saveCompletedOrder(order);

    return order;
  }

  String _generateOrderNumber(DateTime date) {
    return 'ORD-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}-${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}';
  }
}
