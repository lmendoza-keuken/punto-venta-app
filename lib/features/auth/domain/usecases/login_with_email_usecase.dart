import 'package:punto_venta_app/features/auth/domain/repositories/auth_repository.dart';

class LoginWithEmailUsecase {
  final AuthRepository repository;

  LoginWithEmailUsecase(this.repository);

  Future<Map<String, dynamic>> call(String email) async {
    return await repository.loginWithEmail(email);
  }
}
