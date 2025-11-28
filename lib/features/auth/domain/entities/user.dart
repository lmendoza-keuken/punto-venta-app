import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String tipo;
  final String? email;
  final String? photoUrl;
  final List<int>? companyIds;
  final String? idsup;
  final String? supervisor;

  const User({
    required this.id,
    required this.name,
    required this.tipo,
    this.email,
    this.photoUrl,
    this.companyIds,
    this.idsup,
    this.supervisor,
  });

  // Getter para compatibilidad con código existente
  String get username => id;
  String get role => tipo;

  @override
  List<Object?> get props => [id, name, tipo, email, photoUrl, companyIds, idsup, supervisor];
}