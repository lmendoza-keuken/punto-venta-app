import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';
import '../../domain/entities/product.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductModel with _$ProductModel {
  const ProductModel._();

  const factory ProductModel({
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'fractional') int? fractional,
    @JsonKey(name: 'stock') int? stock,
    @JsonKey(name: 'supplier_id') int? supplierId,
    @JsonKey(name: 'vat') double? vat,
    @JsonKey(name: 'internal_tax') int? internalTax,
    @JsonKey(name: 'is_weighted') String? isWeighted,
    @JsonKey(name: 'net_weight') double? netWeight,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'suspended_for_sale') String? suspendedForSale,
    @JsonKey(name: 'suspended_for_purchase') String? suspendedForPurchase,
    @JsonKey(name: 'is_active') String? isActive,
    @JsonKey(name: 'category_description') String? categoryDescription,
    @JsonKey(name: 'oferta') int? oferta,
    @JsonKey(name: 'precio') double? precio,
    @JsonKey(name: 'barcodes') List<BarcodeModel>? barcodes,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Product toEntity() {
    double? precioValue;
    try {
      if (precio != null && precio != '-') {
        precioValue = precio;
      }
    } catch (e) {
      precioValue = null;
    }

    return Product(
      id: id ?? 0,
      description: description ?? '',
      fractional: fractional ?? 0,
      stock: stock ?? 0,
      supplierId: supplierId ?? 0,
      vat: vat ?? 0.0,
      internalTax: internalTax ?? 0,
      isWeighted: isWeighted ?? '',
      netWeight: netWeight ?? 0.0,
      categoryId: categoryId ?? '',
      suspendedForSale: suspendedForSale ?? 'N',
      suspendedForPurchase: suspendedForPurchase ?? 'N',
      isActive: isActive ?? 'S',
      categoryDescription: categoryDescription ?? '',
      precio: precioValue,
      oferta: (oferta ?? 0) == 1,
      barcodes: barcodes,
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      description: product.description,
      fractional: product.fractional,
      stock: product.stock,
      supplierId: product.supplierId,
      vat: product.vat,
      internalTax: product.internalTax,
      isWeighted: product.isWeighted,
      netWeight: product.netWeight,
      categoryId: product.categoryId,
      suspendedForSale: product.suspendedForSale,
      suspendedForPurchase: product.suspendedForPurchase,
      isActive: product.isActive,
      categoryDescription: product.categoryDescription,
      precio: product.precio,
      oferta: product.oferta ? 1 : 0,
      barcodes: product.barcodes,
    );
  }
}
