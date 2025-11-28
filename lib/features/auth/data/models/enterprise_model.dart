import 'package:json_annotation/json_annotation.dart';
import 'package:punto_venta_app/features/auth/domain/entities/enterprise.dart';

part 'enterprise_model.g.dart';

@JsonSerializable()
class EnterpriseModel {
  final int id;
  final String name;

  const EnterpriseModel({
    required this.id,
    required this.name,
  });

  factory EnterpriseModel.fromJson(Map<String, dynamic> json) =>
      _$EnterpriseModelFromJson(json);

  Map<String, dynamic> toJson() => _$EnterpriseModelToJson(this);

  factory EnterpriseModel.fromApiJson(
    Map<String, dynamic> json,
    String email,
    int companyId,
  ) {
    return EnterpriseModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }

  Enterprise toEntity() {
    return Enterprise(
      id: id,
      name: name,
    );
  }

  factory EnterpriseModel.fromEntity(Enterprise enterprise) {
    return EnterpriseModel(
      id: enterprise.id,
      name: enterprise.name,
    );
  }
}
