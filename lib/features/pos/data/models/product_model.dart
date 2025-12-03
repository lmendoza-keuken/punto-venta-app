import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';
import '../../domain/entities/product.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductModel with _$ProductModel {
  const ProductModel._();

  const factory ProductModel({
    int? codigo,
    String? descripcion,
    String? precio,
    String? oferta,
    String? marca,
    String? capacidad,
    int? pack,
    int? uxb,
    int? lanzamiento,
    String? rubro,
    String? linea,
    String? sublinea,
    String? novedad,
    String? pesopromedio,
    String? formaventa,
    int? promocional,
    String? iva,
    @JsonKey(name: 'tipo_producto') int? tipoProducto,
    String? costo,
    String? codcombo,
    @JsonKey(name: 'suspendido_venta') String? suspendidoVenta,
    @JsonKey(name: 'suspendido_quiebre') String? suspendidoQuiebre,
    @JsonKey(name: 'id_proveedor') int? idProveedor,
    @JsonKey(name: 'percepcion_iva') String? percepcionIva,
    @JsonKey(name: 'sku_proveedor') int? skuProveedor,
    @JsonKey(name: 'id_categoria_proveedor') String? idCategoriaProveedor,
    @JsonKey(name: 'id_marca_proveedor') String? idMarcaProveedor,
    int? objetivable,
    @JsonKey(name: 'impuesto_interno') double? impuestoInterno,
    @JsonKey(name: 'usa_listaPrecios') bool? usaListaPrecios,
    List<BarcodeModel>? barcodes,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Product toEntity() {
    double? precioValue;
    try {
      if (precio != null && precio!.isNotEmpty && precio != '-') {
        precioValue = double.parse(precio!.replaceAll(',', '.'));
      }
    } catch (e) {
      precioValue = null;
    }

    return Product(
      codigo: codigo ?? 0,
      descripcion: descripcion ?? 'Producto sin descripción',
      precio: precioValue,
      rubro: rubro ?? 'Sin categoría',
      marca: marca ?? 'Sin marca',
      capacidad: capacidad ?? '',
      pack: pack ?? 1,
      uxb: uxb ?? 1,
      linea: linea ?? 'Sin línea',
      sublinea: sublinea ?? 'Sin sublínea',
      pesopromedio: pesopromedio ?? '0',
      formaventa: formaventa ?? 'U',
      iva:
          iva != null ? double.tryParse(iva!.replaceAll(',', '.')) ?? 0.0 : 0.0,
      costo: costo != null
          ? double.tryParse(costo!.replaceAll(',', '.')) ?? 0.0
          : 0.0,
      suspendidoVenta: suspendidoVenta ?? 'N',
      suspendidoQuiebre: suspendidoQuiebre ?? 'N',
      idProveedor: idProveedor ?? 0,
      objetivable: (objetivable ?? 1) == 1,
      usaListaPrecios: usaListaPrecios ?? true,
      oferta: (oferta ?? "0") == "1",
      barcodes: barcodes,
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      codigo: product.codigo,
      descripcion: product.descripcion,
      precio: product.precio?.toStringAsFixed(3),
      oferta: product.oferta ? "1" : "0",
      marca: product.marca,
      capacidad: product.capacidad,
      pack: product.pack,
      uxb: product.uxb,
      lanzamiento: 0,
      rubro: product.rubro,
      linea: product.linea,
      sublinea: product.sublinea,
      novedad: "0",
      pesopromedio: product.pesopromedio,
      formaventa: product.formaventa,
      promocional: 0,
      iva: product.iva.toStringAsFixed(2),
      tipoProducto: 0,
      costo: product.costo.toStringAsFixed(4),
      codcombo: null,
      suspendidoVenta: product.suspendidoVenta,
      suspendidoQuiebre: product.suspendidoQuiebre,
      idProveedor: product.idProveedor,
      percepcionIva: "3.00",
      skuProveedor: 0,
      idCategoriaProveedor: "0",
      idMarcaProveedor: "0",
      objetivable: product.objetivable ? 1 : 0,
      impuestoInterno: 0.0,
      usaListaPrecios: product.usaListaPrecios,
      barcodes: product.barcodes,
    );
  }
}
