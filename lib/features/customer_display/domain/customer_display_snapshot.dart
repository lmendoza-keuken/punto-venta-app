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
  return customerDisplayBasePriceWithTax(
    basePrice: product.price ?? 0.0,
    vat: product.vat,
    internalTax: product.internalTax,
    fractional: product.fractional ?? 1,
  );
}

double customerDisplayBasePriceWithTax({
  required double basePrice,
  required double vat,
  required double internalTax,
  int fractional = 1,
}) {
  double unit = basePrice * (1 + vat / 100.0);
  if (internalTax > 0) {
    unit += internalTax * fractional;
  }
  return unit;
}

/// Producto en el carrusel de publicidad (fuera del POS).
class CustomerDisplayAdProduct extends Equatable {
  final int productId;
  final String name;
  final String? imageUrl;
  final double unitPrice;
  final bool isOnSale;
  final double? regularPrice;

  const CustomerDisplayAdProduct({
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.unitPrice,
    this.isOnSale = false,
    this.regularPrice,
  });

  factory CustomerDisplayAdProduct.fromProduct(Product product) {
    final unit = customerDisplayUnitPriceWithTax(product);
    double? regular;
    if (product.isOnSale && product.regularPrice != null) {
      regular = customerDisplayBasePriceWithTax(
        basePrice: product.regularPrice!,
        vat: product.vat,
        internalTax: product.internalTax,
        fractional: product.fractional ?? 1,
      );
    }
    return CustomerDisplayAdProduct(
      productId: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      unitPrice: unit,
      isOnSale: product.isOnSale,
      regularPrice: regular,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'unitPrice': unitPrice,
        'isOnSale': isOnSale,
        if (regularPrice != null) 'regularPrice': regularPrice,
      };

  factory CustomerDisplayAdProduct.fromJson(Map<String, dynamic> json) {
    return CustomerDisplayAdProduct(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      isOnSale: json['isOnSale'] as bool? ?? false,
      regularPrice: (json['regularPrice'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props =>
      [productId, name, imageUrl, unitPrice, isOnSale, regularPrice];
}

class CustomerDisplayLineItem extends Equatable {
  final String name;
  final String quantityLabel;
  final double unitPrice;
  final double lineTotal;
  final bool isOnSale;

  const CustomerDisplayLineItem({
    required this.name,
    required this.quantityLabel,
    required this.unitPrice,
    required this.lineTotal,
    this.isOnSale = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantityLabel': quantityLabel,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
        'isOnSale': isOnSale,
      };

  factory CustomerDisplayLineItem.fromJson(Map<String, dynamic> json) {
    return CustomerDisplayLineItem(
      name: json['name'] as String? ?? '',
      quantityLabel: json['quantityLabel'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      isOnSale: json['isOnSale'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [name, quantityLabel, unitPrice, lineTotal, isOnSale];
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
  final bool isOnSale;
  final double? regularUnitPrice;
  final double? regularLineTotal;

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
    this.isOnSale = false,
    this.regularUnitPrice,
    this.regularLineTotal,
  });

  factory CustomerDisplayLastProduct.fromLogEntry(CartLogEntry entry) {
    final isAdd = entry.type == CartActionType.add;
    final sign = isAdd ? '+' : '-';
    final product = entry.item.product;
    final isWeighted = entry.item.isWeighted ?? false;
    final qty = isWeighted
        ? (entry.item.weightKg ?? 0.0)
        : entry.item.quantity.toDouble();
    final unitPrice = customerDisplayUnitPriceWithTax(product);
    final lineTotal = unitPrice * qty;

    double? regularUnit;
    double? regularLine;
    if (product.isOnSale && product.regularPrice != null) {
      regularUnit = customerDisplayBasePriceWithTax(
        basePrice: product.regularPrice!,
        vat: product.vat,
        internalTax: product.internalTax,
        fractional: product.fractional ?? 1,
      );
      regularLine = regularUnit * qty;
    }

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
      isOnSale: product.isOnSale,
      regularUnitPrice: regularUnit,
      regularLineTotal: regularLine,
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
        'isOnSale': isOnSale,
        if (regularUnitPrice != null) 'regularUnitPrice': regularUnitPrice,
        if (regularLineTotal != null) 'regularLineTotal': regularLineTotal,
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
      isOnSale: json['isOnSale'] as bool? ?? false,
      regularUnitPrice: (json['regularUnitPrice'] as num?)?.toDouble(),
      regularLineTotal: (json['regularLineTotal'] as num?)?.toDouble(),
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
        isOnSale,
        regularUnitPrice,
        regularLineTotal,
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

  final String? adTitle;

  final String? adMessage;
  final List<CustomerDisplayAdProduct> adProducts;

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
    this.adTitle,
    this.adMessage,
    this.adProducts = const [],
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
        adTitle = null,
        adMessage = null,
        adProducts = const [],
        isProcessing = false;

  factory CustomerDisplaySnapshot.advertising({
    String? adTitle,
    String? adMessage,
    List<CustomerDisplayAdProduct> adProducts = const [],
  }) {
    return CustomerDisplaySnapshot(
      mode: CustomerDisplayMode.advertising,
      adTitle: adTitle,
      adMessage: adMessage,
      adProducts: adProducts,
    );
  }

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
      isOnSale: item.product.isOnSale,
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
        if (adTitle != null) 'adTitle': adTitle,
        if (adMessage != null) 'adMessage': adMessage,
        if (adProducts.isNotEmpty)
          'adProducts': adProducts.map((e) => e.toJson()).toList(),
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
    final rawAds = json['adProducts'] as List<dynamic>? ?? const [];
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
      adTitle: json['adTitle'] as String?,
      adMessage: json['adMessage'] as String?,
      adProducts: rawAds
          .whereType<Map>()
          .map((e) => CustomerDisplayAdProduct.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
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
    String? adTitle,
    String? adMessage,
    List<CustomerDisplayAdProduct>? adProducts,
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
      adTitle: adTitle ?? this.adTitle,
      adMessage: adMessage ?? this.adMessage,
      adProducts: adProducts ?? this.adProducts,
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
        adTitle,
        adMessage,
        adProducts,
        isProcessing,
      ];
}
