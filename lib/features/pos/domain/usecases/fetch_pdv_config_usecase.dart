import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';

class FetchPdvConfigUsecase {
  final PdvConfigRepository repository;

  FetchPdvConfigUsecase(this.repository);

  Future<PdvConfig> call() async {
    return await repository.fetchPdvConfig();
  }
}
