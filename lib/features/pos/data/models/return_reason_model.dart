import 'package:json_annotation/json_annotation.dart';

part 'return_reason_model.g.dart';

@JsonSerializable()
class ReturnReasonModel {
  final int id;
  final String description;
  final String? code;

  const ReturnReasonModel({
    required this.id,
    required this.description,
    this.code,
  });

  factory ReturnReasonModel.fromJson(Map<String, dynamic> json) =>
      _$ReturnReasonModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReturnReasonModelToJson(this);
}
