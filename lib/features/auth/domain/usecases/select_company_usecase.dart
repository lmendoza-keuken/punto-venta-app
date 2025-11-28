import 'package:punto_venta_app/features/auth/domain/repositories/auth_repository.dart';

class SelectCompanyUseCase {
  final AuthRepository repository;

  SelectCompanyUseCase(this.repository);

  Future<Map<String, dynamic>> call(String email, int companyId) async {
    return await repository.selectCompany(email, companyId);
  }
}