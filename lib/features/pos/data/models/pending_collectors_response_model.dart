import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_collectors_response_model.freezed.dart';
part 'pending_collectors_response_model.g.dart';

@freezed
class PendingCollectorsResponseModel with _$PendingCollectorsResponseModel {
  const PendingCollectorsResponseModel._();

  const factory PendingCollectorsResponseModel({
    @JsonKey(name: 'user_id') int? userId,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'total') double? total,
  }) = _PendingCollectorsResponseModel;

  factory PendingCollectorsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PendingCollectorsResponseModelFromJson(json);
}
