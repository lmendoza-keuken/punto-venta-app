import 'package:punto_venta_app/features/auth/domain/repositories/auth_repository.dart';

class LoginWithGoogleUsecase {
  final AuthRepository repository;

  LoginWithGoogleUsecase(this.repository);

  Future<Map<String, dynamic>> call() async {
    return await repository.loginWithGoogle();
  }
}

