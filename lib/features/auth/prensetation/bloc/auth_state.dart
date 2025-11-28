import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/auth/domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthCompanySelectionRequired extends AuthState {
  final String email;
  final List<Map<String, dynamic>> companies;
  final bool autoSelected;

  const AuthCompanySelectionRequired({
    required this.email,
    required this.companies,
    required this.autoSelected,
  });

  @override
  List<Object> get props => [email, companies, autoSelected];
}

class AuthCompanySelected extends AuthState {
  final String email;
  final int companyId;
  final String companyName;

  const AuthCompanySelected({
    required this.email,
    required this.companyId,
    required this.companyName,
  });

  @override
  List<Object> get props => [email, companyId, companyName];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}
