import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';

class Product extends Equatable {
  final int id;
  final String description;
  final int? fractional;
  final int stock;
  final int supplierId;
  final double vat;
  final int internalTax;
  final String isWeighted;
  final double netWeight;
  final String categoryId;
  final String suspendedForSale;
  final String suspendedForPurchase;
  final String isActive;
  final String categoryDescription;
  
  final double? price; // precio actual (siempre mostrar este)
  final double? regularPrice; // precio anterior (solo mostrar tachado si hay oferta)
  final bool isOnSale; // true si está en oferta, false si no
  final List<BarcodeModel>? barcodes;

  const Product({
    required this.id,
    required this.description,
    this.fractional,
    required this.stock,
    required this.supplierId,
    required this.vat,
    required this.internalTax,
    required this.isWeighted,
    required this.netWeight,
    required this.categoryId,
    required this.suspendedForSale,
    required this.suspendedForPurchase,
    required this.isActive,
    required this.categoryDescription,
    this.price,
    this.regularPrice,
    required this.isOnSale,
    this.barcodes,
  });

  String get idStr => id.toString();
  String get name => description.trim();
  String get code => id.toString();
  String get category => categoryDescription.isNotEmpty ? categoryDescription : categoryId;
  String? get imageUrl => null;

  @override
  List<Object?> get props => [
        id,
        description,
        fractional,
        stock,
        supplierId,
        vat,
        internalTax,
        isWeighted,
        netWeight,
        categoryId,
        suspendedForSale,
        suspendedForPurchase,
        isActive,
        categoryDescription,
        price,
        regularPrice,
        isOnSale,
        barcodes,
      ];
}
