import 'package:freezed_annotation/freezed_annotation.dart';

part 'mp_credentials_model.freezed.dart';
part 'mp_credentials_model.g.dart';

@freezed
class MpCredentials with _$MpCredentials {
  factory MpCredentials({
    @JsonKey(name: 'mpAccessToken') String? mpAccessToken,
    @JsonKey(name: 'mpExternalPosIds')
    List<ExternalPosIdModel>? mpExternalPosIds,
    @JsonKey(name: 'mpStore') StoreModel? mpStore,
  }) = _MpCredentials;

  factory MpCredentials.fromJson(Map<String, dynamic> json) =>
      _$MpCredentialsFromJson(json);
}

@freezed
class ExternalPosIdModel with _$ExternalPosIdModel {
  factory ExternalPosIdModel({
    @JsonKey(name: 'mpExternalPosId') String? mpExternalPosId,
    @JsonKey(name: 'userId') int? userId,
  }) = _ExternalPosIdModel;

  factory ExternalPosIdModel.fromJson(Map<String, dynamic> json) =>
      _$ExternalPosIdModelFromJson(json);
}

@freezed
class StoreModel with _$StoreModel {
  factory StoreModel({
    @JsonKey(name: 'storeId') String? storeId,
    @JsonKey(name: 'mpExternalStoreId') String? mpExternalStoreId,
  }) = _StoreModel;

  factory StoreModel.fromJson(Map<String, dynamic> json) =>
      _$StoreModelFromJson(json);
}
