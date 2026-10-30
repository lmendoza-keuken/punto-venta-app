import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_disposed_items_response_model.freezed.dart';
part 'pending_disposed_items_response_model.g.dart';

@freezed
class PendingDisposedGroupModel with _$PendingDisposedGroupModel {
  const PendingDisposedGroupModel._();

  const factory PendingDisposedGroupModel({
    @JsonKey(name: 'disposeId') String? disposeId,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'timestamp') String? timestamp,
    @JsonKey(name: 'disposed_items') List<DisposedItemModel>? disposedItems,
  }) = _PendingDisposedGroupModel;

  factory PendingDisposedGroupModel.fromJson(Map<String, dynamic> json) =>
      _$PendingDisposedGroupModelFromJson(json);

  int get disposedItemsCount =>
      disposedItems?.fold<int>(
            0,
            (sum, item) => sum + (item.quantity ?? 0).round(),
          ) ??
          0;
}

@freezed
class DisposedItemModel with _$DisposedItemModel {
  const factory DisposedItemModel({
    @JsonKey(name: 'productId') int? productId,
    @JsonKey(name: 'productName') String? productName,
    @JsonKey(name: 'quantity') double? quantity,
    @JsonKey(name: 'is_weighted') String? isWeighted,
    @JsonKey(name: 'weight') double? weight,
  }) = _DisposedItemModel;

  factory DisposedItemModel.fromJson(Map<String, dynamic> json) =>
      _$DisposedItemModelFromJson(json);
}
