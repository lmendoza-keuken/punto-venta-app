import 'package:punto_venta_app/features/pos/domain/entities/ticket_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/ticket_config_repository.dart';

class GetTicketConfigUsecase {
  final TicketConfigRepository repository;

  GetTicketConfigUsecase(this.repository);

  Future<TicketConfig?> call() async {
    return await repository.getTicketConfig();
  }
}
