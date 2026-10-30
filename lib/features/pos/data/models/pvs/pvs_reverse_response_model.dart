import 'package:freezed_annotation/freezed_annotation.dart';

part 'pvs_reverse_response_model.freezed.dart';
part 'pvs_reverse_response_model.g.dart';

@freezed
class PvsReverseResponse with _$PvsReverseResponse {
  const factory PvsReverseResponse({
    @JsonKey(name: 'qrId') String? qrId,
  }) = _PvsReverseResponse;

  factory PvsReverseResponse.fromJson(Map<String, dynamic> json) =>
      _$PvsReverseResponseFromJson(json);
}
