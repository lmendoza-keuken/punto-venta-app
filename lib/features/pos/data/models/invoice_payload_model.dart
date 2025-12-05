import 'package:punto_venta_app/features/pos/data/models/cart_item_model.dart';
import 'package:punto_venta_app/features/pos/data/models/cart_log_entry_model.dart';
import 'package:punto_venta_app/features/pos/data/models/client_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
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
        final unitPrice = itemModel.product.precio ?? 0.0;
        final quantity = itemModel.quantity;
        final weightKg = itemLog.item.weightKg;
        final isWeighted = (itemLog.item.isWeighted);

        return {
          'id': cartLogItem.id,
          'type': cartLogItem.type.toString(),
          'productId': itemModel.product.id,
          'productName': itemModel.product.description,
          'is_weighted': isWeighted == true ? "S" : "N",
          'net_weight': isWeighted == true ? itemModel.product.netWeight : null,
          'discount': 0,
          'quantity': isWeighted == true ? weightKg ?? 0.0 : quantity,
          'unitPrice': unitPrice,
          'vat': itemModel.iva,
          'internal_tax': itemModel.product.internalTax,
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
      logItems: job.logItems.map(serializeCartLogItem).toList(),
    );
  }
}
