import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';

enum CustomerDisplayMode { idle, cart, payment, done, advertising }

/// Fase del cobro QR en la pantalla cliente (polling MP/PVS).
enum CustomerDisplayQrPhase {
  none,
  ready,
  pending,
  approved,
  rejected,
  expired,
}

/// Precio unitario al público (base + IVA + impuesto interno), igual que el log del POS.
double customerDisplayUnitPriceWithTax(Product product) {
  final basePrice = product.price ?? 0.0;
  final vatRate = product.vat / 100.0;
  final internalTax = product.internalTax;
  final fractional = product.fractional ?? 1;

  double unit = basePrice * (1 + vatRate);
  if (internalTax > 0) {
    unit += internalTax * fractional;
  }
  return unit;
}

class CustomerDisplayLineItem extends Equatable {
  final String name;
  final String quantityLabel;
  final double unitPrice;
  final double lineTotal;

  const CustomerDisplayLineItem({
    required this.name,
    required this.quantityLabel,
    required this.unitPrice,
    required this.lineTotal,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantityLabel': quantityLabel,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
      };

  factory CustomerDisplayLineItem.fromJson(Map<String, dynamic> json) {
    return CustomerDisplayLineItem(
      name: json['name'] as String? ?? '',
      quantityLabel: json['quantityLabel'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [name, quantityLabel, unitPrice, lineTotal];
}

/// Último producto del log (mismo preview que el carrito en modo scanner).
class CustomerDisplayLastProduct extends Equatable {
  final String entryId;
  final int productId;
  final String name;
  final String? imageUrl;
  final bool isAdd;
  final bool isWeighted;
  final String quantityLabel;
  final double unitPrice;
  final double lineTotal;

  const CustomerDisplayLastProduct({
    required this.entryId,
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.isAdd,
    required this.isWeighted,
    required this.quantityLabel,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory CustomerDisplayLastProduct.fromLogEntry(CartLogEntry entry) {
    final isAdd = entry.type == CartActionType.add;
    final sign = isAdd ? '+' : '-';
    final product = entry.item.product;
    final isWeighted = entry.item.isWeighted ?? false;
    final unitPrice = customerDisplayUnitPriceWithTax(product);
    final lineTotal = isWeighted
        ? unitPrice * (entry.item.weightKg ?? 0.0)
        : unitPrice * entry.item.quantity;

    final quantityLabel = isWeighted
        ? '$sign${entry.item.weightKg ?? 0} kg'
        : '$sign${entry.item.quantity}';

    return CustomerDisplayLastProduct(
      entryId: entry.id,
      productId: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      isAdd: isAdd,
      isWeighted: isWeighted,
      quantityLabel: quantityLabel,
      unitPrice: unitPrice,
      lineTotal: lineTotal,
    );
  }

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'productId': productId,
        'name': name,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'isAdd': isAdd,
        'isWeighted': isWeighted,
        'quantityLabel': quantityLabel,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
      };

  factory CustomerDisplayLastProduct.fromJson(Map<String, dynamic> json) {
    return CustomerDisplayLastProduct(
      entryId: json['entryId'] as String? ?? '',
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      isAdd: json['isAdd'] as bool? ?? true,
      isWeighted: json['isWeighted'] as bool? ?? false,
      quantityLabel: json['quantityLabel'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        entryId,
        productId,
        name,
        imageUrl,
        isAdd,
        isWeighted,
        quantityLabel,
        unitPrice,
        lineTotal,
      ];
}

class CustomerDisplaySnapshot extends Equatable {
  final CustomerDisplayMode mode;
  final List<CustomerDisplayLineItem> items;
  final double subtotal;
  final double totalConIva;
  final CustomerDisplayLastProduct? lastProduct;

  /// Etiqueta del medio QR (ej. "Mercado Pago", "PVS").
  final String? qrLabel;

  /// Payload para generar el QR. Si es null se muestra placeholder.
  final String? qrPayload;

  /// Fase del QR (approved/pending/…) sincronizada desde el polling del POS.
  final CustomerDisplayQrPhase qrPhase;

  /// Detalle opcional (ID de pago, motivo de rechazo, etc.).
  final String? qrDetail;

  /// True solo mientras [CheckoutBloc] está en [CheckoutProcessing].
  final bool isProcessing;

  const CustomerDisplaySnapshot({
    required this.mode,
    this.items = const [],
    this.subtotal = 0,
    this.totalConIva = 0,
    this.lastProduct,
    this.qrLabel,
    this.qrPayload,
    this.qrPhase = CustomerDisplayQrPhase.none,
    this.qrDetail,
    this.isProcessing = false,
  });

  const CustomerDisplaySnapshot.idle()
      : mode = CustomerDisplayMode.idle,
        items = const [],
        subtotal = 0,
        totalConIva = 0,
        lastProduct = null,
        qrLabel = null,
        qrPayload = null,
        qrPhase = CustomerDisplayQrPhase.none,
        qrDetail = null,
        isProcessing = false;

  const CustomerDisplaySnapshot.advertising()
      : mode = CustomerDisplayMode.advertising,
        items = const [],
        subtotal = 0,
        totalConIva = 0,
        lastProduct = null,
        qrLabel = null,
        qrPayload = null,
        qrPhase = CustomerDisplayQrPhase.none,
        qrDetail = null,
        isProcessing = false;

  factory CustomerDisplaySnapshot.fromCartLoaded(
    CartLoaded cart, {
    CustomerDisplayMode mode = CustomerDisplayMode.cart,
    String? qrLabel,
    String? qrPayload,
    CustomerDisplayQrPhase qrPhase = CustomerDisplayQrPhase.none,
    String? qrDetail,
    bool isProcessing = false,
  }) {
    final last = cart.log.isNotEmpty
        ? CustomerDisplayLastProduct.fromLogEntry(cart.log.last)
        : null;

    return CustomerDisplaySnapshot(
      mode: mode,
      items: cart.items.map(_mapItem).toList(),
      subtotal: cart.subtotal,
      totalConIva: cart.totalConIva,
      lastProduct: last,
      qrLabel: qrLabel,
      qrPayload: qrPayload,
      qrPhase: qrPhase,
      qrDetail: qrDetail,
      isProcessing: isProcessing,
    );
  }

  static CustomerDisplayLineItem _mapItem(CartItem item) {
    final isWeighted = item.isWeighted == true;
    // Mismo criterio que el log del POS / product card: precio con IVA + impuesto interno.
    final unit = customerDisplayUnitPriceWithTax(item.product);
    final lineTotal = isWeighted
        ? unit * (item.weightKg ?? 0.0)
        : unit * item.quantity;
    final quantityLabel = isWeighted
        ? '${(item.weightKg ?? 0).toStringAsFixed(3)} kg'
        : 'x${item.quantity}';
    return CustomerDisplayLineItem(
      name: item.product.name,
      quantityLabel: quantityLabel,
      unitPrice: unit,
      lineTotal: lineTotal,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'totalConIva': totalConIva,
        if (lastProduct != null) 'lastProduct': lastProduct!.toJson(),
        if (qrLabel != null) 'qrLabel': qrLabel,
        if (qrPayload != null) 'qrPayload': qrPayload,
        'qrPhase': qrPhase.name,
        if (qrDetail != null) 'qrDetail': qrDetail,
        'isProcessing': isProcessing,
      };

  factory CustomerDisplaySnapshot.fromJson(Map<String, dynamic> json) {
    final modeName = json['mode'] as String? ?? 'idle';
    final mode = CustomerDisplayMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => CustomerDisplayMode.idle,
    );
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final rawLast = json['lastProduct'];
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
      lastProduct: rawLast is Map
          ? CustomerDisplayLastProduct.fromJson(
              Map<String, dynamic>.from(rawLast),
            )
          : null,
      qrLabel: json['qrLabel'] as String?,
      qrPayload: json['qrPayload'] as String?,
      qrPhase: CustomerDisplayQrPhase.values.firstWhere(
        (p) => p.name == (json['qrPhase'] as String? ?? 'none'),
        orElse: () => CustomerDisplayQrPhase.none,
      ),
      qrDetail: json['qrDetail'] as String?,
      isProcessing: json['isProcessing'] as bool? ?? false,
    );
  }

  CustomerDisplaySnapshot copyWith({
    CustomerDisplayMode? mode,
    List<CustomerDisplayLineItem>? items,
    double? subtotal,
    double? totalConIva,
    CustomerDisplayLastProduct? lastProduct,
    String? qrLabel,
    String? qrPayload,
    CustomerDisplayQrPhase? qrPhase,
    String? qrDetail,
    bool? isProcessing,
    bool clearQr = false,
    bool clearLastProduct = false,
  }) {
    return CustomerDisplaySnapshot(
      mode: mode ?? this.mode,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      totalConIva: totalConIva ?? this.totalConIva,
      lastProduct:
          clearLastProduct ? null : (lastProduct ?? this.lastProduct),
      qrLabel: clearQr ? null : (qrLabel ?? this.qrLabel),
      qrPayload: clearQr ? null : (qrPayload ?? this.qrPayload),
      qrPhase: clearQr
          ? CustomerDisplayQrPhase.none
          : (qrPhase ?? this.qrPhase),
      qrDetail: clearQr ? null : (qrDetail ?? this.qrDetail),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        items,
        subtotal,
        totalConIva,
        lastProduct,
        qrLabel,
        qrPayload,
        qrPhase,
        qrDetail,
        isProcessing,
      ];
}
