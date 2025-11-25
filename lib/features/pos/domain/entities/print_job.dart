import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';

class PrintJob {
  final List<CartItem> items;
  final List<CartLogEntry> logItems;
  final double total;
  final String? clientName;
  final String cashierName;
  final DateTime timestamp;
  final String ticketId;

  const PrintJob({
    required this.items,
    required this.logItems,
    required this.total,
    this.clientName,
    required this.cashierName,
    required this.timestamp,
    required this.ticketId,
  });
}