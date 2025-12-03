import 'package:json_annotation/json_annotation.dart';

part 'precio_articulo_model.g.dart';

@JsonSerializable()
class PrecioArticuloModel {
  @JsonKey(name: 'id_producto')
  final int producto;

  @JsonKey(name: 'id_lista', fromJson: _idListaFromJson, toJson: _idListaToJson)
  final int listaPrecio;

  final String precio;
  final String oferta;

  const PrecioArticuloModel({
    required this.producto,
    required this.listaPrecio,
    required this.precio,
    required this.oferta,
  });

  factory PrecioArticuloModel.fromJson(Map<String, dynamic> json) =>
      _$PrecioArticuloModelFromJson(json);

  Map<String, dynamic> toJson() => _$PrecioArticuloModelToJson(this);

  double get precioDouble {
    try {
      return double.parse(precio.replaceAll(',', '.'));
    } catch (e) {
      return 0.0;
    }
  }

  bool get esOferta => oferta == "1" || oferta == "true";

  static int _idListaFromJson(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static dynamic _idListaToJson(int value) => value;
}
