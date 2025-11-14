import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/product.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final int? codigo;
  final String? descripcion;
  @JsonKey(name: 'lista1')
  final String? lista1;
  @JsonKey(name: 'oferta1')
  final String? oferta1;
  @JsonKey(name: 'lista2')
  final String? lista2;
  @JsonKey(name: 'oferta2')
  final String? oferta2;
  @JsonKey(name: 'lista3')
  final String? lista3;
  @JsonKey(name: 'oferta3')
  final String? oferta3;
  @JsonKey(name: 'lista4')
  final String? lista4;
  @JsonKey(name: 'oferta4')
  final String? oferta4;
  @JsonKey(name: 'lista5')
  final String? lista5;
  @JsonKey(name: 'oferta5')
  final String? oferta5;
  @JsonKey(name: 'lista6')
  final String? lista6;
  @JsonKey(name: 'oferta6')
  final String? oferta6;
  @JsonKey(name: 'lista7')
  final String? lista7;
  @JsonKey(name: 'oferta7')
  final String? oferta7;
  @JsonKey(name: 'lista8')
  final String? lista8;
  @JsonKey(name: 'oferta8')
  final String? oferta8;
  @JsonKey(name: 'lista9')
  final String? lista9;
  @JsonKey(name: 'oferta9')
  final String? oferta9;
  @JsonKey(name: 'lista10')
  final String? lista10;
  @JsonKey(name: 'oferta10')
  final String? oferta10;
  @JsonKey(name: 'lista11')
  final String? lista11;
  @JsonKey(name: 'oferta11')
  final String? oferta11;
  @JsonKey(name: 'lista12')
  final String? lista12;
  @JsonKey(name: 'oferta12')
  final String? oferta12;
  @JsonKey(name: 'lista13')
  final String? lista13;
  @JsonKey(name: 'oferta13')
  final String? oferta13;
  @JsonKey(name: 'lista14')
  final String? lista14;
  @JsonKey(name: 'oferta14')
  final String? oferta14;
  @JsonKey(name: 'lista15')
  final String? lista15;
  @JsonKey(name: 'oferta15')
  final String? oferta15;
  @JsonKey(name: 'lista16')
  final String? lista16;
  @JsonKey(name: 'oferta16')
  final String? oferta16;
  @JsonKey(name: 'lista17')
  final String? lista17;
  @JsonKey(name: 'oferta17')
  final String? oferta17;
  @JsonKey(name: 'lista18')
  final String? lista18;
  @JsonKey(name: 'oferta18')
  final String? oferta18;
  @JsonKey(name: 'lista19')
  final String? lista19;
  @JsonKey(name: 'oferta19')
  final String? oferta19;
  @JsonKey(name: 'lista20')
  final String? lista20;
  @JsonKey(name: 'oferta20')
  final String? oferta20;
  final String? marca;
  final String? capacidad;
  final int? pack;
  final int? uxb;
  final int? lanzamiento;
  final String? rubro;
  final String? linea;
  final String? sublinea;
  final String? novedad;
  final String? pesopromedio;
  final String? formaventa;
  final int? promocional;
  final String? iva;
  @JsonKey(name: 'tipo_producto')
  final int? tipoProducto;
  final String? costo;
  final String? codcombo;
  @JsonKey(name: 'suspendido_venta')
  final String? suspendidoVenta;
  @JsonKey(name: 'suspendido_quiebre')
  final String? suspendidoQuiebre;
  @JsonKey(name: 'id_proveedor')
  final int? idProveedor;
  @JsonKey(name: 'percepcion_iva')
  final String? percepcionIva;
  @JsonKey(name: 'sku_proveedor')
  final int? skuProveedor;
  @JsonKey(name: 'id_categoria_proveedor')
  final String? idCategoriaProveedor;
  @JsonKey(name: 'id_marca_proveedor')
  final String? idMarcaProveedor;
  final int? objetivable;
  @JsonKey(name: 'impuesto_interno')
  final double? impuestoInterno;
  @JsonKey(name: 'usa_listaPrecios')
  final bool? usaListaPrecios;

  const ProductModel({
    this.codigo,
    this.descripcion,
    this.lista1,
    this.oferta1,
    this.lista2,
    this.oferta2,
    this.lista3,
    this.oferta3,
    this.lista4,
    this.oferta4,
    this.lista5,
    this.oferta5,
    this.lista6,
    this.oferta6,
    this.lista7,
    this.oferta7,
    this.lista8,
    this.oferta8,
    this.lista9,
    this.oferta9,
    this.lista10,
    this.oferta10,
    this.lista11,
    this.oferta11,
    this.lista12,
    this.oferta12,
    this.lista13,
    this.oferta13,
    this.lista14,
    this.oferta14,
    this.lista15,
    this.oferta15,
    this.lista16,
    this.oferta16,
    this.lista17,
    this.oferta17,
    this.lista18,
    this.oferta18,
    this.lista19,
    this.oferta19,
    this.lista20,
    this.oferta20,
    this.marca,
    this.capacidad,
    this.pack,
    this.uxb,
    this.lanzamiento,
    this.rubro,
    this.linea,
    this.sublinea,
    this.novedad,
    this.pesopromedio,
    this.formaventa,
    this.promocional,
    this.iva,
    this.tipoProducto,
    this.costo,
    this.codcombo,
    this.suspendidoVenta,
    this.suspendidoQuiebre,
    this.idProveedor,
    this.percepcionIva,
    this.skuProveedor,
    this.idCategoriaProveedor,
    this.idMarcaProveedor,
    this.objetivable,
    this.impuestoInterno,
    this.usaListaPrecios,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  Product toEntity() {
    // Convertir lista13 a double para el precio con valores por defecto
    double precio = 0.0;
    try {
      if (lista13 != null && lista13!.isNotEmpty) {
        precio = double.parse(lista13!.replaceAll(',', '.'));
      }
    } catch (e) {
      precio = 0.0;
    }

    // Convertir iva a double con valor por defecto
    double ivaValue = 21.0;
    try {
      if (iva != null && iva!.isNotEmpty) {
        ivaValue = double.parse(iva!.replaceAll(',', '.'));
      }
    } catch (e) {
      ivaValue = 21.0;
    }

    // Convertir costo a double con valor por defecto
    double costoValue = 0.0;
    try {
      if (costo != null && costo!.isNotEmpty) {
        costoValue = double.parse(costo!.replaceAll(',', '.'));
      }
    } catch (e) {
      costoValue = 0.0;
    }

    return Product(
      codigo: codigo ?? 0,
      descripcion: descripcion ?? 'Producto sin descripción',
      precio: precio,
      rubro: rubro ?? 'Sin categoría',
      marca: marca ?? 'Sin marca',
      capacidad: capacidad ?? '',
      pack: pack ?? 1,
      uxb: uxb ?? 1,
      linea: linea ?? 'Sin línea',
      sublinea: sublinea ?? 'Sin sublínea',
      pesopromedio: pesopromedio ?? '0',
      formaventa: formaventa ?? 'U',
      iva: ivaValue,
      costo: costoValue,
      suspendidoVenta: suspendidoVenta ?? 'N',
      suspendidoQuiebre: suspendidoQuiebre ?? 'N',
      idProveedor: idProveedor ?? 0,
      objetivable: (objetivable ?? 1) == 1,
      usaListaPrecios: usaListaPrecios ?? true,
      oferta: (oferta13 ?? "0") == "1",
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      codigo: product.codigo,
      descripcion: product.descripcion,
      lista1: "0.000",
      oferta1: "0",
      lista2: "0.000",
      oferta2: "0",
      lista3: "0.000",
      oferta3: "0",
      lista4: "0.000",
      oferta4: "0",
      lista5: "0.000",
      oferta5: "0",
      lista6: "0.000",
      oferta6: "0",
      lista7: "0.000",
      oferta7: "0",
      lista8: "0.000",
      oferta8: "0",
      lista9: "0.000",
      oferta9: "0",
      lista10: "0.000",
      oferta10: "0",
      lista11: "0.000",
      oferta11: "0",
      lista12: "0.000",
      oferta12: "0",
      lista13: product.precio.toStringAsFixed(3),
      oferta13: product.oferta ? "1" : "0",
      lista14: "0.000",
      oferta14: "0",
      lista15: "0.000",
      oferta15: "0",
      lista16: "0.000",
      oferta16: "0",
      lista17: "0.000",
      oferta17: "0",
      lista18: "0.000",
      oferta18: "0",
      lista19: "0.000",
      oferta19: "0",
      lista20: "0.000",
      oferta20: "0",
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
    );
  }
}
