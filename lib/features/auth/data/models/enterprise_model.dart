import 'package:json_annotation/json_annotation.dart';
import 'package:punto_venta_app/features/auth/domain/entities/enterprise.dart';

part 'enterprise_model.g.dart';

@JsonSerializable()
class EnterpriseModel {
  final int id;
  final String name;
  final String? baseUrl;
  @JsonKey(defaultValue: <String>[])
  final List<String> baseUrls;
  final int? listPriceId;

  const EnterpriseModel({
    required this.id,
    required this.name,
    this.baseUrl,
    this.baseUrls = const [],
    this.listPriceId,
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
      baseUrl: json['baseUrl']?.toString(),
      baseUrls: (json['baseUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      listPriceId: json['listPriceId'] ?? 0,
    );
  }

  Enterprise toEntity() {
    return Enterprise(
      id: id,
      name: name,
      baseUrl: baseUrl,
      baseUrls: baseUrls,
      listPriceId: listPriceId,
    );
  }

  factory EnterpriseModel.fromEntity(Enterprise enterprise) {
    return EnterpriseModel(
      id: enterprise.id,
      name: enterprise.name,
      baseUrl: enterprise.baseUrl,
      baseUrls: enterprise.baseUrls,
      listPriceId: enterprise.listPriceId,
    );
  }

  EnterpriseModel copyWith({
    int? id,
    String? name,
    String? baseUrl,
    List<String>? baseUrls,
    int? listPriceId,
  }) {
    return EnterpriseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      baseUrls: baseUrls ?? this.baseUrls,
      listPriceId: listPriceId ?? this.listPriceId,
    );
  }
}
