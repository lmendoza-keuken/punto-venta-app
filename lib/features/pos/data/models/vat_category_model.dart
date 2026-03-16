import 'package:freezed_annotation/freezed_annotation.dart';

part 'vat_category_model.freezed.dart';
part 'vat_category_model.g.dart';

@freezed
class VatCategoryModel with _$VatCategoryModel {
  const VatCategoryModel._();

  const factory VatCategoryModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'letter') String? letter,
    @JsonKey(name: 'tax_rate') double? taxRate,
    @JsonKey(name: 'surcharge_rate') double? surchargeRate,
    @JsonKey(name: 'ib_perception') String? ibPerception,
    @JsonKey(name: 'municipal_perceptions') String? municipalPerceptions,
    @JsonKey(name: 'apply_per_vat') bool? applyPerVat,
  }) = _VatCategoryModel;

  factory VatCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$VatCategoryModelFromJson(json);
}
