import 'package:equatable/equatable.dart';

enum UserRole {
  admin,
  ven,
  unknown,
}

extension UserRoleX on UserRole {
  String get code {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.ven:
        return 'VEN';
      case UserRole.unknown:
        return 'UNKNOWN';
    }
  }

  static UserRole fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'VEN':
        return UserRole.ven;
      default:
        return UserRole.unknown;
    }
  }
}

class User extends Equatable {
  final String id;
  final String name;
  final String password;
  final String tipo;
  final String? isActive;
  final String? phoneNumber;

  const User({
    required this.id,
    required this.name,
    required this.tipo,
    required this.password,
    this.isActive,
    this.phoneNumber,
  });

  UserRole get role => UserRoleX.fromCode(tipo);
  String get roleCode => role.code;

  @override
  List<Object?> get props => [id, name, tipo, password, isActive, phoneNumber];
}
