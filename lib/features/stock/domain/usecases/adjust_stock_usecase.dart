import 'package:punto_venta_app/features/stock/domain/repositories/stock_repository.dart';

class AdjustStockUsecase {
  final StockRepository repository;

  AdjustStockUsecase(this.repository);

  Future<void> call({
    required int productCodigo,
    required int newStock,
    required String reason,
    required String userId,
    required String userName,
  }) async {
    await repository.adjustStock(
      productCodigo,
      newStock,
      reason,
      userId,
      userName,
    );
  }
}