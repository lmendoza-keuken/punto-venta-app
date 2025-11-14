import 'package:pos_flutter_app/features/auth/domain/entities/user.dart';
import 'package:pos_flutter_app/features/auth/domain/repositories/auth_repository.dart';

class LoginUsecase {
  final AuthRepository repository;

  LoginUsecase(this.repository);

  Future<User> call(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Usuario y contraseña son requeridos');
    }

    return await repository.login(username, password);
  }
}
