import 'package:punto_venta_app/features/pos/data/datasources/ticket_config_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/ticket_config_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/ticket_config_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/ticket_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/ticket_config_repository.dart';

class TicketConfigRepositoryImpl implements TicketConfigRepository {
  final TicketConfigLocalDataSource localDataSource;
  final TicketConfigRemoteDataSource remoteDataSource;

  TicketConfigRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<TicketConfig?> getTicketConfig() async {
    try {
      final configModel = await localDataSource.getTicketConfig();
      return configModel?.toEntity();
    } catch (e) {
      throw Exception('Error al obtener configuración local de tickets: $e');
    }
  }

  @override
  Future<TicketConfig> fetchTicketConfig() async {
    try {
      // TODO: Descomentar cuando el backend esté listo
      // final configModel = await remoteDataSource.fetchTicketConfig();
      // await localDataSource.saveTicketConfig(configModel);
      // return configModel.toEntity();

      // Temporalmente: usar configuración local
      final localConfig = await localDataSource.getTicketConfig();

      if (localConfig != null) {
        return localConfig.toEntity();
      }

      final defaultConfig = TicketConfigModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        showSubtotalAndTax: false,
        showPricesWithTax: true,
        lastUpdated: DateTime.now(),
      );

      await localDataSource.saveTicketConfig(defaultConfig);
      return defaultConfig.toEntity();
    } catch (e) {
      throw Exception('Error al obtener configuración de tickets: $e');
    }
  }

  @override
  Future<TicketConfig> updateTicketConfig(TicketConfig config) async {
    try {
      final configModel = TicketConfigModel.fromEntity(config);

      // TODO: Descomentar cuando el backend esté listo
      // final updatedModel = await remoteDataSource.updateTicketConfig(configModel);
      // await localDataSource.saveTicketConfig(updatedModel);
      // return updatedModel.toEntity();

      // Temporalmente: solo guardar localmente
      await localDataSource.saveTicketConfig(configModel);
      return configModel.toEntity();
    } catch (e) {
      throw Exception('Error al actualizar configuración de tickets: $e');
    }
  }

  @override
  Future<void> saveTicketConfigLocally(TicketConfig config) async {
    try {
      final configModel = TicketConfigModel.fromEntity(config);
      await localDataSource.saveTicketConfig(configModel);
    } catch (e) {
      throw Exception('Error al guardar configuración local de tickets: $e');
    }
  }

  @override
  Future<void> deleteTicketConfig() async {
    try {
      await localDataSource.deleteTicketConfig();
    } catch (e) {
      throw Exception('Error al eliminar configuración de tickets: $e');
    }
  }
}
