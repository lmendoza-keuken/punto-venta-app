import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';

class FetchBranchesUsecase {
  final PdvConfigRepository repository;

  FetchBranchesUsecase(this.repository);

  Future<List<Branch>> call() async {
    return await repository.fetchBranches();
  }
}
