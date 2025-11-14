import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String name;
  final String role;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  @override
  List<Object> get props => [id, username, name, role];
}