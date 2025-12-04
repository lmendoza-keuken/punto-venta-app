import 'package:freezed_annotation/freezed_annotation.dart';

part 'barcode_model.freezed.dart';
part 'barcode_model.g.dart';

@freezed
class BarcodeModel with _$BarcodeModel {
  const BarcodeModel._();

  const factory BarcodeModel({
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'article_id') int? articleId,
    @JsonKey(name: 'barcode') int? barcode,
    @JsonKey(name: 'units') int? units,
    @JsonKey(name: 'type') int? type,
  }) = _BarcodeModel;

  factory BarcodeModel.fromJson(Map<String, dynamic> json) =>
      _$BarcodeModelFromJson(json);

  bool get isWeighted => barcode.toString().startsWith('20');

  String get saleTypeText {
    switch (type) {
      case 1:
        return 'Unidad';
      case 2:
        return 'Pack';
      case 3:
        return 'Bulto';
      default:
        return 'Desconocido';
    }
  }
}
