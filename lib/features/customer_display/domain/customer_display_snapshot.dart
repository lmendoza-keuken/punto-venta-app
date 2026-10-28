import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';

enum CustomerDisplayMode { idle, cart, payment, done }

class CustomerDisplayLineItem extends Equatable {
  final String name;
  final String quantityLabel;
  final double lineTotal;

  const CustomerDisplayLineItem({
    required this.name,
    required this.quantityLabel,
    required this.lineTotal,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantityLabel': quantityLabel,
        'lineTotal': lineTotal,
      };

  factory CustomerDisplayLineItem.fromJson(Map<String, dynamic> json) {
    return CustomerDisplayLineItem(
      name: json['name'] as String? ?? '',
      quantityLabel: json['quantityLabel'] as String? ?? '',
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [name, quantityLabel, lineTotal];
}

class CustomerDisplaySnapshot extends Equatable {
  final CustomerDisplayMode mode;
  final List<CustomerDisplayLineItem> items;
  final double subtotal;
  final double totalConIva;

  const CustomerDisplaySnapshot({
    required this.mode,
    this.items = const [],
    this.subtotal = 0,
    this.totalConIva = 0,
  });

  const CustomerDisplaySnapshot.idle()
      : mode = CustomerDisplayMode.idle,
        items = const [],
        subtotal = 0,
        totalConIva = 0;

  factory CustomerDisplaySnapshot.fromCartLoaded(
    CartLoaded cart, {
    CustomerDisplayMode mode = CustomerDisplayMode.cart,
  }) {
    return CustomerDisplaySnapshot(
      mode: mode,
      items: cart.items.map(_mapItem).toList(),
      subtotal: cart.subtotal,
      totalConIva: cart.totalConIva,
    );
  }

  static CustomerDisplayLineItem _mapItem(CartItem item) {
    final isWeighted = item.isWeighted == true;
    final quantityLabel = isWeighted
        ? '${(item.weightKg ?? 0).toStringAsFixed(3)} kg'
        : 'x${item.quantity}';
    return CustomerDisplayLineItem(
      name: item.product.description,
      quantityLabel: quantityLabel,
      lineTotal: item.totalPrice,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'totalConIva': totalConIva,
      };

  factory CustomerDisplaySnapshot.fromJson(Map<String, dynamic> json) {
    final modeName = json['mode'] as String? ?? 'idle';
    final mode = CustomerDisplayMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => CustomerDisplayMode.idle,
    );
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return CustomerDisplaySnapshot(
      mode: mode,
      items: rawItems
          .whereType<Map>()
          .map((e) => CustomerDisplayLineItem.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      totalConIva: (json['totalConIva'] as num?)?.toDouble() ?? 0,
    );
  }

  CustomerDisplaySnapshot copyWith({
    CustomerDisplayMode? mode,
    List<CustomerDisplayLineItem>? items,
    double? subtotal,
    double? totalConIva,
  }) {
    return CustomerDisplaySnapshot(
      mode: mode ?? this.mode,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      totalConIva: totalConIva ?? this.totalConIva,
    );
  }

  @override
  List<Object?> get props => [mode, items, subtotal, totalConIva];
}
