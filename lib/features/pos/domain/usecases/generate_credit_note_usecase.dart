import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/completed_orders_repository.dart';

class GenerateCreditNoteUsecase {
  final CompletedOrdersRepository repository;

  GenerateCreditNoteUsecase(this.repository);

  Future<CompletedOrder?> call(String ticketId) async {
    return await repository.convertToCreditNote(ticketId);
  }
}
