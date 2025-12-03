import 'package:equatable/equatable.dart';

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

  String get role => tipo;

  @override
  List<Object?> get props =>
      [id, name, tipo, password, isActive, phoneNumber];
}
