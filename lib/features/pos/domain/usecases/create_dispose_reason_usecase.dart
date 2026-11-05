import 'package:punto_venta_app/features/pos/domain/entities/dispose_reason.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/stock_dispose_repository.dart';

class CreateDisposeReasonUsecase {
  final StockDisposeRepository repository;

  CreateDisposeReasonUsecase(this.repository);

  Future<DisposeReason> call({
    required String code,
    required String description,
  }) {
    return repository.createDisposeReason(
      code: code,
      description: description,
    );
  }
}
