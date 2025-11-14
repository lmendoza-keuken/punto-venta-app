import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int codigo;
  final String descripcion;
  final double precio; // Usaremos lista13 como precio base
  final String rubro; // Categoría basada en rubro
  final String marca;
  final String capacidad;
  final int pack;
  final int uxb;
  final String linea;
  final String sublinea;
  final String pesopromedio;
  final String formaventa;
  final double iva;
  final double costo;
  final String suspendidoVenta;
  final String suspendidoQuiebre;
  final int idProveedor;
  final bool objetivable;
  final bool usaListaPrecios;
  final bool oferta; // Si oferta13 es 1

  const Product({
    required this.codigo,
    required this.descripcion,
    required this.precio,
    required this.rubro,
    required this.marca,
    required this.capacidad,
    required this.pack,
    required this.uxb,
    required this.linea,
    required this.sublinea,
    required this.pesopromedio,
    required this.formaventa,
    required this.iva,
    required this.costo,
    required this.suspendidoVenta,
    required this.suspendidoQuiebre,
    required this.idProveedor,
    required this.objetivable,
    required this.usaListaPrecios,
    required this.oferta,
  });

  // Getters para compatibilidad con el código existente
  String get id => codigo.toString();
  String get name => descripcion.trim();
  String get code => codigo.toString();
  String get category => rubro;
  String? get imageUrl => null; // No hay imágenes en la API
  int get stock => suspendidoVenta == 'N' ? 100 : 0; // Simular stock
  String get description => '$marca - $descripcion';

  @override
  List<Object?> get props => [
        codigo,
        descripcion,
        precio,
        rubro,
        marca,
        capacidad,
        pack,
        uxb,
        linea,
        sublinea,
        pesopromedio,
        formaventa,
        iva,
        costo,
        suspendidoVenta,
        suspendidoQuiebre,
        idProveedor,
        objetivable,
        usaListaPrecios,
        oferta,
      ];
}
