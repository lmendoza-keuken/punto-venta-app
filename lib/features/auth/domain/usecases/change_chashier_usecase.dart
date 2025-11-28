import 'package:punto_venta_app/features/auth/domain/repositories/auth_repository.dart';

class ChangeCashierUseCase {
  final AuthRepository repository;

  ChangeCashierUseCase(this.repository);

  Future<void> call() async {
    return await repository.changeCashier();
  }
}