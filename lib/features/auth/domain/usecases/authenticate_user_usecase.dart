import 'package:punto_venta_app/features/auth/domain/entities/user.dart';
import 'package:punto_venta_app/features/auth/domain/repositories/auth_repository.dart';

class AuthenticateUserUseCase {
  final AuthRepository repository;

  AuthenticateUserUseCase(this.repository);

  Future<User> call(
    String email,
    int companyId,
    String username,
    String password,
  ) async {
    return await repository.authenticateUser(email, companyId, username, password);
  }
}