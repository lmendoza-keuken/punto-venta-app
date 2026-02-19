import 'package:punto_venta_app/features/pos/domain/entities/ticket_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/ticket_config_repository.dart';

class UpdateTicketConfigUsecase {
  final TicketConfigRepository repository;

  UpdateTicketConfigUsecase(this.repository);

  Future<TicketConfig> call(TicketConfig config) async {
    return await repository.updateTicketConfig(config);
  }
}
