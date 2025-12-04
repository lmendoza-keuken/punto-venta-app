import 'package:json_annotation/json_annotation.dart';

part 'precio_articulo_model.g.dart';

@JsonSerializable()
class PrecioArticuloModel {
  @JsonKey(name: 'product_id')
  final int productId;

  @JsonKey(name: 'list_id', fromJson: _idListaFromJson, toJson: _idListaToJson)
  final int listId;

  @JsonKey(name: 'price')
  final String price;
  @JsonKey(name: 'sale_price')
  final String salePrice;

  const PrecioArticuloModel({
    required this.productId,
    required this.listId,
    required this.price,
    required this.salePrice,
  });

  factory PrecioArticuloModel.fromJson(Map<String, dynamic> json) =>
      _$PrecioArticuloModelFromJson(json);

  Map<String, dynamic> toJson() => _$PrecioArticuloModelToJson(this);

  double get priceAsDouble {
    try {
      return double.parse(price.replaceAll(',', '.'));
    } catch (e) {
      return 0.0;
    }
  }

  bool get isSalePrice => salePrice == "1" || salePrice == "true";

  static int _idListaFromJson(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static dynamic _idListaToJson(int value) => value;
}
