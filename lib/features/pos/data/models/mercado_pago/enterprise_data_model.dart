import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/core/utils/json_converters.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/mp_credentials_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/pvs_credentials_model.dart';

part 'enterprise_data_model.freezed.dart';
part 'enterprise_data_model.g.dart';

@freezed
class EnterpriseDataModel with _$EnterpriseDataModel {
  factory EnterpriseDataModel({
    @JsonKey(name: 'id', fromJson: convertToInt) int? id,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'mpCredentials') MpCredentials? mpCredentials,
    @JsonKey(name: 'pvsCredentials') List<PvsCredentials>? pvsCredentials,
  }) = _EnterpriseDataModel;

  factory EnterpriseDataModel.fromJson(Map<String, dynamic> json) =>
      _$EnterpriseDataModelFromJson(json);
}
