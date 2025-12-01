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
  final String cashier;
  final Map<String, dynamic> client;
  final String paymentMethod;
  final double total;
  final double totalTax;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> logItems;
  final int? priceListId;

  InvoicePayload({
    required this.ticketId,
    required this.timestamp,
    required this.cashier,
    required this.client,
    required this.paymentMethod,
    required this.total,
    required this.totalTax,
    required this.items,
    required this.logItems,
    this.priceListId,
  });

  Map<String, dynamic> toJson() => {
        'ticketId': ticketId,
        'timestamp': timestamp,
        'cashier': cashier,
        'client': client,
        'paymentMethod': paymentMethod,
        'total': total,
        'totalTax': totalTax,
        'items': items,
        'logItems': logItems,
        'priceListId': priceListId,
      };

  factory InvoicePayload.fromPrintJob(PrintJob job) {
    Map<String, dynamic> serializeClient(Client? c) {
      if (c == null) return {};
      try {
        return (c as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        final model = ClientModel.fromEntity(c);
        return model.toJson();
      }
    }

    Map<String, dynamic> serializeCartItem(CartItem item) {
      try {
        return (item as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        final model = CartItemModel.fromEntity(item);
        final unitPrice = double.tryParse(model.product.lista13?.replaceAll(',', '.') ?? '') ?? 0.0;
        final quantity = model.quantity;
        return {
          'productId': model.product.codigo,
          'productName': model.product.descripcion,
          'quantity': quantity,
          'discount': 0,
          'unitPrice': unitPrice,
          'totalItem': (unitPrice * (quantity.toDouble())),
        };
      }
    }

    Map<String, dynamic> serializeCartLogItem(CartLogEntry itemLog) {
      try {
        return (itemLog as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        final cartLogItem = CartLogEntryModel.fromEntity(itemLog);
        final itemModel = CartItemModel.fromEntity(itemLog.item);
        final unitPrice = double.tryParse(itemModel.product.lista13?.replaceAll(',', '.') ?? '') ?? 0.0;
        final quantity = itemModel.quantity;
        return {
          'id': cartLogItem.id,
          'type': cartLogItem.type.toString(),
          'productId': itemModel.product.codigo,
          'productName': itemModel.product.descripcion,
          'discount': 0,
          'quantity': quantity,
          'unitPrice': unitPrice,
        };
      }
    }



    return InvoicePayload(
      ticketId: job.ticketId,
      timestamp: job.timestamp.toIso8601String(),
      cashier: job.cashierName,
      client: serializeClient(job.client),
      paymentMethod: job.paymentMethod ?? '',
      total: job.total,
      totalTax: job.totalTax,
      items: job.items.map(serializeCartItem).toList(),
      logItems: job.logItems.map(serializeCartLogItem).toList(),
      priceListId: job.priceListId,
    );
  }
}