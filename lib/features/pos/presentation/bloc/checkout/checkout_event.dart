import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class ProcessSale extends CheckoutEvent {
  final List<CartItem> items;
  final List<CartLogEntry> logItems;
  final double total;
  final double totalIva;
  final double subtotal;
  final Client? client;
  final PaymentMethod? paymentMethod;
  final List<PaymentMethod>? paymentMethods;
  final double? receivedAmount;
  final double? change;

  const ProcessSale({
    required this.items,
    required this.logItems,
    required this.total,
    required this.totalIva,
    required this.subtotal,
    this.client,
    this.paymentMethod,
    this.paymentMethods,
    this.receivedAmount,
    this.change,
  });

  @override
  List<Object?> get props => [
        items,
        logItems,
        total,
        totalIva,
        subtotal,
        client,
        paymentMethod,
        paymentMethods,
        receivedAmount,
        change,
      ];
}

class ResetCheckout extends CheckoutEvent {
  const ResetCheckout();
}

class ConfirmReturn extends CheckoutEvent {
  final int reasonId;
  final List<CartItem> items;
  final List<CartLogEntry> logItems;

  const ConfirmReturn({
    required this.reasonId,
    required this.items,
    required this.logItems,
  });

  @override
  List<Object?> get props => [reasonId, items, logItems];
}
