import 'package:punto_venta_app/features/stock/domain/repositories/stock_repository.dart';

class AddStockUsecase {
  final StockRepository repository;

  AddStockUsecase(this.repository);

  Future<void> call({
    required int productCodigo,
    required int quantity,
    required String reason,
    required String userId,
    required String userName,
  }) async {
    await repository.addStock(
      productCodigo,
      quantity,
      reason,
      userId,
      userName,
    );
  }
}