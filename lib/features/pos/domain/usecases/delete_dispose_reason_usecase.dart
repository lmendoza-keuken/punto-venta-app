import 'package:punto_venta_app/features/pos/domain/repositories/stock_dispose_repository.dart';

class DeleteDisposeReasonUsecase {
  final StockDisposeRepository repository;

  DeleteDisposeReasonUsecase(this.repository);

  Future<void> call(int reasonId) => repository.deleteDisposeReason(reasonId);
}
