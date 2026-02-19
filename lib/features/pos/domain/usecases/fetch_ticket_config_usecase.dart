import 'package:punto_venta_app/features/pos/domain/entities/ticket_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/ticket_config_repository.dart';

class FetchTicketConfigUsecase {
  final TicketConfigRepository repository;

  FetchTicketConfigUsecase(this.repository);

  Future<TicketConfig> call() async {
    return await repository.fetchTicketConfig();
  }
}
