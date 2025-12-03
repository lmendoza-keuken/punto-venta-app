import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';

class PrintJob {
  final List<CartItem> items;
  final List<CartLogEntry> logItems;
  final double total;
  final double totalTax;
  final String? clientName;
  final Client? client;
  final int? priceListId;
  final String? paymentMethod;
  final String? cashierName;
  final int? cashierId;
  final DateTime timestamp;
  final String ticketId;

  const PrintJob({
    required this.items,
    required this.logItems,
    required this.total,
    required this.totalTax,
    this.client,
    this.clientName,
    this.priceListId,
    this.paymentMethod,
    required this.cashierName,
    this.cashierId,
    required this.timestamp,
    required this.ticketId,
  });
}