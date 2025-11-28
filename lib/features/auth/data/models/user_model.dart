import 'package:json_annotation/json_annotation.dart';
import 'package:punto_venta_app/features/auth/domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  @JsonKey(name: 'tipo')
  final String tipo;
  final String? email;
  final String? photoUrl;
  final List<int>? companyIds;
  final String? idsup;
  final String? supervisor;

  const UserModel({
    required this.id,
    required this.name,
    required this.tipo,
    this.email,
    this.photoUrl,
    this.companyIds,
    this.idsup,
    this.supervisor,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromApiJson(
    Map<String, dynamic> json,
    String email,
    int companyId,
  ) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'VEN',
      email: email,
      photoUrl: null,
      companyIds: [companyId],
      idsup: json['idsup']?.toString(),
      supervisor: json['supervisor']?.toString(),
    );
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      tipo: tipo,
      email: email,
      photoUrl: photoUrl,
      companyIds: companyIds,
      idsup: idsup,
      supervisor: supervisor,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      tipo: user.tipo,
      email: user.email,
      photoUrl: user.photoUrl,
      companyIds: user.companyIds,
      idsup: user.idsup,
      supervisor: user.supervisor,
    );
  }
}
