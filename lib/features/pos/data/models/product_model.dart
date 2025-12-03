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
    @JsonKey(name: 'descri_comercial') String? descriComercial,
    @JsonKey(name: 'fraccionado') int? fraccionado,
    @JsonKey(name: 'stock') int? stock,
    @JsonKey(name: 'id_proveedor') int? idProveedor,
    @JsonKey(name: 'iva') double? iva,
    @JsonKey(name: 'impint') int? impint,
    @JsonKey(name: 'sepesa') String? sepesa,
    @JsonKey(name: 'pesoneto') double? pesoneto,
    @JsonKey(name: 'idrubro') String? idRubro,
    @JsonKey(name: 'suspendido_venta') String? suspendidoVenta,
    @JsonKey(name: 'suspendido_para_compra') String? suspendidoParaCompra,
    @JsonKey(name: 'activo') String? activo,
    @JsonKey(name: 'descripcion_rubro') String? descripcionRubro,
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
      descripcionComercial: descriComercial ?? '',
      fraccionado: fraccionado ?? 0,
      stock: stock ?? 0,
      idProveedor: idProveedor ?? 0,
      iva: iva ?? 0.0,
      impint: impint ?? 0,
      sepesa: sepesa ?? '',
      pesoneto: pesoneto ?? 0.0,
      idRubro: idRubro ?? '',
      suspendidoVenta: suspendidoVenta ?? 'N',
      suspendidoParaCompra: suspendidoParaCompra ?? 'N',
      activo: activo ?? 'S',
      descripcionRubro: descripcionRubro ?? '',
      precio: precioValue,
      oferta: (oferta ?? 0) == 1,
      barcodes: barcodes,
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      descriComercial: product.descripcionComercial,
      fraccionado: product.fraccionado,
      stock: product.stock,
      idProveedor: product.idProveedor,
      iva: product.iva,
      impint: product.impint,
      sepesa: product.sepesa,
      pesoneto: product.pesoneto,
      idRubro: product.idRubro,
      suspendidoVenta: product.suspendidoVenta,
      suspendidoParaCompra: product.suspendidoParaCompra,
      activo: product.activo,
      descripcionRubro: product.descripcionRubro,
      precio: product.precio,
      oferta: product.oferta ? 1 : 0,
      barcodes: product.barcodes,
    );
  }
}
