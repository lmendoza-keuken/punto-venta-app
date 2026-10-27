import 'package:punto_venta_app/features/auth/domain/repositories/auth_repository.dart';

class RefreshCompaniesUseCase {
  final AuthRepository repository;

  RefreshCompaniesUseCase(this.repository);

  Future<Map<String, dynamic>> call() async {
    return await repository.refreshCompaniesForCachedEmail();
  }
}
