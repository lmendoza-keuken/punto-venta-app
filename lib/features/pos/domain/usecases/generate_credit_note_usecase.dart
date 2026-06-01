import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/completed_orders_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/returns_repository.dart';

class GenerateCreditNoteUsecase {
  final ReturnsRepository returnsRepository;
  final CompletedOrdersRepository completedOrdersRepository;

  GenerateCreditNoteUsecase({
    required this.returnsRepository,
    required this.completedOrdersRepository,
  });

  Future<CompletedOrder?> call(String ticketId, int reasonId) async {
    final saleId = int.tryParse(ticketId);
    if (saleId == null) {
      throw Exception('ID de ticket inválido: $ticketId');
    }

    final payload =
        await returnsRepository.processTotalReturn(saleId, reasonId);
    return completedOrdersRepository.fromInvoicePayload(payload);
  }
}
