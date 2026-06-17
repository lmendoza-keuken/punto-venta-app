import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/completed_orders_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/returns_repository.dart';
import 'package:punto_venta_app/features/pos/data/models/partial_return_request_model.dart';

class ProcessPartialReturnUseCase {
  final ReturnsRepository returnsRepository;
  final CompletedOrdersRepository completedOrdersRepository;

  ProcessPartialReturnUseCase({
    required this.returnsRepository,
    required this.completedOrdersRepository,
  });

  Future<CompletedOrder?> call(PartialReturnRequestModel request) async {
    final payload = await returnsRepository.processPartialReturn(request);
    return completedOrdersRepository.fromInvoicePayload(payload);
  }
}
