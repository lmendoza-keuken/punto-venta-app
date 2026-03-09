import 'package:freezed_annotation/freezed_annotation.dart';

part 'tax_model.freezed.dart';
part 'tax_model.g.dart';

@freezed
class TaxModel with _$TaxModel {
  const TaxModel._();

  const factory TaxModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'descripcion') String? description,
    @JsonKey(name: 'porcentaje') double? percentage,
    @JsonKey(name: 'amount') double? amount,
  }) = _TaxModel;

  factory TaxModel.fromJson(Map<String, dynamic> json) =>
      _$TaxModelFromJson(json);
}
