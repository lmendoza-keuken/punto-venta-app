import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';

class Product extends Equatable {
  final int id;
  final String descripcionComercial;
  final int? fraccionado;
  final int stock;
  final int idProveedor;
  final double iva;
  final int impint;
  final String sepesa;
  final double pesoneto;
  final String idRubro;
  final String suspendidoVenta;
  final String suspendidoParaCompra;
  final String activo;
  final String descripcionRubro;
  final double? precio;
  final bool oferta;
  final List<BarcodeModel>? barcodes;

  const Product({
    required this.id,
    required this.descripcionComercial,
    this.fraccionado,
    required this.stock,
    required this.idProveedor,
    required this.iva,
    required this.impint,
    required this.sepesa,
    required this.pesoneto,
    required this.idRubro,
    required this.suspendidoVenta,
    required this.suspendidoParaCompra,
    required this.activo,
    required this.descripcionRubro,
    this.precio,
    required this.oferta,
    this.barcodes,
  });

  String get idStr => id.toString();
  String get name => descripcionComercial.trim();
  String get code => id.toString();
  String get category => descripcionRubro.isNotEmpty ? descripcionRubro : idRubro;
  String? get imageUrl => null;

  @override
  List<Object?> get props => [
        id,
        descripcionComercial,
        fraccionado,
        stock,
        idProveedor,
        iva,
        impint,
        sepesa,
        pesoneto,
        idRubro,
        suspendidoVenta,
        suspendidoParaCompra,
        activo,
        descripcionRubro,
        precio,
        oferta,
        barcodes,
      ];
}
