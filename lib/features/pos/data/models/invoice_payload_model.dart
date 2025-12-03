import 'package:punto_venta_app/features/pos/data/models/cart_item_model.dart';
import 'package:punto_venta_app/features/pos/data/models/cart_log_entry_model.dart';
import 'package:punto_venta_app/features/pos/data/models/client_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';

class InvoicePayload {
  final String ticketId;
  final String timestamp;
  final int? cashier;
  final Map<String, dynamic>? client;
  final String paymentMethod;
  final double total;
  final double totalTax;
  final List<Map<String, dynamic>> logItems;

  InvoicePayload({
    required this.ticketId,
    required this.timestamp,
    this.cashier,
    required this.client,
    required this.paymentMethod,
    required this.total,
    required this.totalTax,
    required this.logItems,
  });

  Map<String, dynamic> toJson() => {
        'ticketId': ticketId,
        'timestamp': timestamp,
        'cashier': cashier,
        'client': client,
        'paymentMethod': paymentMethod,
        'total': total,
        'totalTax': totalTax,
        'items': logItems,
      };

  factory InvoicePayload.fromPrintJob(PrintJob job) {
    Map<String, dynamic>? serializeClient(Client? c) {
      if (c == null) return null;
      try {
        return (c as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        final model = ClientModel.fromEntity(c);
        return model.toJson();
      }
    }

    Map<String, dynamic> serializeCartLogItem(CartLogEntry itemLog) {
      try {
        return (itemLog as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        final cartLogItem = CartLogEntryModel.fromEntity(itemLog);
        final itemModel = CartItemModel.fromEntity(itemLog.item);
        final unitPrice = double.tryParse(
                itemModel.product.precio?.replaceAll(',', '.') ?? '') ??
            0.0;
        final quantity = itemModel.quantity;
        return {
          'id': cartLogItem.id,
          'type': cartLogItem.type.toString(),
          'productId': itemModel.product.codigo,
          'productName': itemModel.product.descripcion,
          'discount': 0,
          'quantity': quantity,
          'unitPrice': unitPrice,
          'iva': itemModel.iva,
          'impuesto_interno': itemModel.product.impuestoInterno,
          'priceListId': job.priceListId,
        };
      }
    }

    return InvoicePayload(
      ticketId: job.ticketId,
      timestamp: job.timestamp.toIso8601String(),
      cashier: job.cashierId,
      client: serializeClient(job.client),
      paymentMethod: job.paymentMethod ?? '',
      total: job.total,
      totalTax: job.totalTax,
      // items: job.items.map(serializeCartItem).toList(),
      logItems: job.logItems.map(serializeCartLogItem).toList(),
    );
  }
}
