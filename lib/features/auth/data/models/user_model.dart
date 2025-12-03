import 'package:json_annotation/json_annotation.dart';
import 'package:punto_venta_app/features/auth/domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  @JsonKey(name: 'role')
  final String tipo;
  final String password;
  final String? isActive;
  final String? phoneNumber;

  const UserModel({
    required this.id,
    required this.name,
    required this.tipo,
    required this.password,
    this.isActive,
    this.phoneNumber,
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
      tipo: json['role']?.toString() ?? 'VEN',
      password: json['password']?.toString() ?? '',
      isActive: json['is_active']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
    );
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      tipo: tipo,
      password: password,
      isActive: isActive,
      phoneNumber: phoneNumber,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      tipo: user.tipo,
      password: user.password,
      isActive: user.isActive,
      phoneNumber: user.phoneNumber,
    );
  }
}
