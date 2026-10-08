import 'package:punto_venta_app/features/pos/domain/entities/return_reason.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/returns_repository.dart';

class FetchReturnReasonsUsecase {
  final ReturnsRepository repository;

  FetchReturnReasonsUsecase(this.repository);

  Future<List<ReturnReason>> call({bool forceRefresh = false}) async {
    return repository.fetchReturnReasons(forceRefresh: forceRefresh);
  }
}
