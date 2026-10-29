import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_dispose_request_model.freezed.dart';
part 'stock_dispose_request_model.g.dart';

@freezed
class StockDisposeRequestModel with _$StockDisposeRequestModel {
  @JsonSerializable(explicitToJson: true)
  const factory StockDisposeRequestModel({
    @JsonKey(name: 'reason_id') required int reasonId,
    @JsonKey(name: 'items', toJson: _itemsToJson)
    required List<StockDisposeItemModel> items,
  }) = _StockDisposeRequestModel;

  factory StockDisposeRequestModel.fromJson(Map<String, dynamic> json) =>
      _$StockDisposeRequestModelFromJson(json);
}

List<Map<String, dynamic>>? _itemsToJson(List<StockDisposeItemModel>? items) =>
    items?.map((e) => e.toJson()).toList();

@freezed
class StockDisposeItemModel with _$StockDisposeItemModel {
  const factory StockDisposeItemModel({
    @JsonKey(name: 'article_id') required int articleId,
    @JsonKey(name: 'quantity') required double quantity,
    @JsonKey(name: 'is_weighted') String? isWeighted,
    @JsonKey(name: 'net_weight') double? netWeight,
    @JsonKey(name: 'weight') double? weight,
  }) = _StockDisposeItemModel;

  factory StockDisposeItemModel.fromJson(Map<String, dynamic> json) =>
      _$StockDisposeItemModelFromJson(json);
}
