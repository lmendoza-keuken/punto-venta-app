import 'package:punto_venta_app/features/pos/domain/repositories/pvs_repository.dart';

class BootstrapPvsCredentialsUsecase {
  final PvsRepository repository;

  BootstrapPvsCredentialsUsecase(this.repository);

  Future<void> call(int enterpriseId) {
    return repository.bootstrapCredentials(enterpriseId);
  }
}
