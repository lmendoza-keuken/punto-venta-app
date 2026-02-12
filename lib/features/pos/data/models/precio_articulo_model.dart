import 'package:json_annotation/json_annotation.dart';

part 'precio_articulo_model.g.dart';

@JsonSerializable()
class PrecioArticuloModel {
  @JsonKey(name: 'product_id')
  final int productId;

  @JsonKey(name: 'list_id', fromJson: _idListaFromJson, toJson: _idListaToJson)
  final int listId;

  @JsonKey(name: 'regular_price')
  final String regularPrice;

  @JsonKey(name: 'price')
  final String price;

  @JsonKey(name: 'is_on_sale')
  final String isOnSale;

  const PrecioArticuloModel({
    required this.productId,
    required this.listId,
    required this.regularPrice,
    required this.price,
    required this.isOnSale,
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

  double get regularPriceAsDouble {
    try {
      return double.parse(regularPrice.replaceAll(',', '.'));
    } catch (e) {
      return 0.0;
    }
  }

  bool get isSalePrice => isOnSale == "1" || isOnSale == "true";

  static int _idListaFromJson(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static dynamic _idListaToJson(int value) => value;
}
