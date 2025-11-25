import 'package:punto_venta_app/features/stock/domain/entities/stock_movement.dart';
import 'package:punto_venta_app/features/stock/domain/repositories/stock_repository.dart';

class GetStockMovementsUsecase {
  final StockRepository repository;

  GetStockMovementsUsecase(this.repository);

  Future<List<StockMovement>> call({
    int? productCodigo,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (productCodigo != null) {
      return await repository.getProductMovements(productCodigo);
    }

    return await repository.getAllMovements(
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}