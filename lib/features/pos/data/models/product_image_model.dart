import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_image_model.freezed.dart';
part 'product_image_model.g.dart';

@freezed
class ProductImageModel with _$ProductImageModel {
  const factory ProductImageModel({
    @JsonKey(name: 'codigo', fromJson: _codigoFromJson) String? codigo,
    @JsonKey(name: 'link') String? link,
    @JsonKey(name: 'image') String? image,
    @JsonKey(name: 'hash') String? hash,
    @JsonKey(name: 'order') int? order,
    @JsonKey(name: 'key') String? key,
    @JsonKey(name: 'tags') List<String>? tags,
    @JsonKey(name: 'backup') bool? backup,
  }) = _ProductImageModel;

  factory ProductImageModel.fromJson(Map<String, dynamic> json) =>
      _$ProductImageModelFromJson(json);
}

String? _codigoFromJson(dynamic value) {
  if (value == null) return null;
  return value.toString();
}
