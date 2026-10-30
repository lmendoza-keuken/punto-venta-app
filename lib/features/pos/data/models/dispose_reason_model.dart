import 'package:punto_venta_app/features/pos/domain/entities/dispose_reason.dart';

class DisposeReasonModel {
  final int id;
  final String description;
  final String? code;
  final String? firebirdCode;
  final bool enabled;

  const DisposeReasonModel({
    required this.id,
    required this.description,
    this.code,
    this.firebirdCode,
    this.enabled = true,
  });

  factory DisposeReasonModel.fromJson(Map<String, dynamic> json) {
    return DisposeReasonModel(
      id: json['id'] as int,
      description: json['description'] as String,
      code: json['code'] as String?,
      firebirdCode: json['firebird_code'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        if (code != null) 'code': code,
        if (firebirdCode != null) 'firebird_code': firebirdCode,
        'enabled': enabled,
      };

  DisposeReason toEntity() {
    return DisposeReason(
      id: id,
      description: description,
      code: code,
      firebirdCode: firebirdCode,
      enabled: enabled,
    );
  }
}
