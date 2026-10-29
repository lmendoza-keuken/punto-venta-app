import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_dispose_response_model.freezed.dart';
part 'stock_dispose_response_model.g.dart';

@freezed
class StockDisposeResponseModel with _$StockDisposeResponseModel {
  const factory StockDisposeResponseModel({
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'user_id') int? userId,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'reason_id') int? reasonId,
    @JsonKey(name: 'synced') bool? synced,
    @JsonKey(name: 'details') @Default([]) List<dynamic> details,
  }) = _StockDisposeResponseModel;

  factory StockDisposeResponseModel.fromJson(Map<String, dynamic> json) =>
      _$StockDisposeResponseModelFromJson(json);
}
