import 'package:punto_venta_app/features/pos/domain/entities/ticket_config.dart';

abstract class TicketConfigRepository {
  Future<TicketConfig?> getTicketConfig();
  Future<TicketConfig> fetchTicketConfig();
  Future<TicketConfig> updateTicketConfig(TicketConfig config);
  Future<void> saveTicketConfigLocally(TicketConfig config);
  Future<void> deleteTicketConfig();
}
