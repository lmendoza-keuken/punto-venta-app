import 'package:punto_venta_app/features/pos/domain/entities/dispose_reason.dart';

class DisposeReasonModel {
  final int id;
  final String description;
  final String? code;

  const DisposeReasonModel({
    required this.id,
    required this.description,
    this.code,
  });

  factory DisposeReasonModel.fromJson(Map<String, dynamic> json) {
    return DisposeReasonModel(
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

  DisposeReason toEntity() {
    return DisposeReason(
      id: id,
      description: description,
      code: code,
    );
  }
}
