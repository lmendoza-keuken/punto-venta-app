import 'package:punto_venta_app/features/pos/domain/entities/return_reason.dart';

class ReturnReasonModel {
  final int id;
  final String description;
  final String? code;

  const ReturnReasonModel({
    required this.id,
    required this.description,
    this.code,
  });

  factory ReturnReasonModel.fromJson(Map<String, dynamic> json) {
    return ReturnReasonModel(
      id: json['id'] as int,
      description: json['description'] as String,
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        if (code != null) 'code': code,
      };

  ReturnReason toEntity() {
    return ReturnReason(
      id: id,
      description: description,
      code: code,
    );
  }
}
