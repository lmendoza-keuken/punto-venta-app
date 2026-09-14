import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_sale_helper.dart';

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
    final info = resolveBarcodeSaleInfo(type: type, units: units);
    if (info == null || info.label.isEmpty) return 'Desconocido';
    return info.label;
  }
}
