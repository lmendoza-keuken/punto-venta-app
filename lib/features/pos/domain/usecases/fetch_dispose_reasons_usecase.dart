import 'package:punto_venta_app/features/pos/domain/entities/dispose_reason.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/stock_dispose_repository.dart';

class FetchDisposeReasonsUsecase {
  final StockDisposeRepository repository;

  FetchDisposeReasonsUsecase(this.repository);

  Future<List<DisposeReason>> call() => repository.fetchDisposeReasons();
}
