import 'package:punto_venta_app/features/stock/domain/repositories/stock_repository.dart';

class RemoveStockUsecase {
  final StockRepository repository;

  RemoveStockUsecase(this.repository);

  Future<void> call({
    required int productCodigo,
    required int quantity,
    required String reason,
    required String userId,
    required String userName,
  }) async {
    await repository.removeStock(
      productCodigo,
      quantity,
      reason,
      userId,
      userName,
    );
  }
}