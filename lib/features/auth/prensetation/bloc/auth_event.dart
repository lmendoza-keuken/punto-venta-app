import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;

  const LoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [username, password];
}

class LoginWithGoogleRequested extends AuthEvent {}

class CompanySelected extends AuthEvent {
  final String email;
  final int companyId;

  const CompanySelected({
    required this.email,
    required this.companyId,
  });

  @override
  List<Object> get props => [email, companyId];
}

class AuthenticateUserRequested extends AuthEvent {
  final String email;
  final int companyId;
  final String username;
  final String password;

  const AuthenticateUserRequested({
    required this.email,
    required this.companyId,
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [email, companyId, username, password];
}

class ChangeCashierRequested extends AuthEvent {} 

class LogoutRequested extends AuthEvent {}

class LogoutEvent extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}