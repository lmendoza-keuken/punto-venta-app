import 'package:punto_venta_app/features/pos/data/datasources/app_config_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/app_config_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/app_config_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/app_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/app_config_repository.dart';

class AppConfigRepositoryImpl implements AppConfigRepository {
  final AppConfigLocalDataSource localDataSource;
  final AppConfigRemoteDataSource remoteDataSource;

  AppConfigRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<AppConfig?> getAppConfig() async {
    try {
      final configModel = await localDataSource.getAppConfig();
      return configModel?.toEntity();
    } catch (e) {
      throw Exception('Error al obtener configuración local de tickets: $e');
    }
  }

  @override
  Future<AppConfig> fetchAppConfig() async {
    try {
      // TODO: Descomentar cuando el backend esté listo
      // final configModel = await remoteDataSource.fetchAppConfig();
      // await localDataSource.saveAppConfig(configModel);
      // return configModel.toEntity();

      // Temporalmente: usar configuración local
      final localConfig = await localDataSource.getAppConfig();

      if (localConfig != null) {
        return localConfig.toEntity();
      }

      final defaultConfig = AppConfigModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        showSubtotalAndTax: false,
        showPricesWithTax: true,
        lastUpdated: DateTime.now(),
      );

      await localDataSource.saveAppConfig(defaultConfig);
      return defaultConfig.toEntity();
    } catch (e) {
      throw Exception('Error al obtener configuración de tickets: $e');
    }
  }

  @override
  Future<AppConfig> updateAppConfig(AppConfig config) async {
    try {
      final configModel = AppConfigModel.fromEntity(config);

      // TODO: Descomentar cuando el backend esté listo
      // final updatedModel = await remoteDataSource.updateAppConfig(configModel);
      // await localDataSource.saveAppConfig(updatedModel);
      // return updatedModel.toEntity();

      // Temporalmente: solo guardar localmente
      await localDataSource.saveAppConfig(configModel);
      return configModel.toEntity();
    } catch (e) {
      throw Exception('Error al actualizar configuración de tickets: $e');
    }
  }

  @override
  Future<void> saveAppConfigLocally(AppConfig config) async {
    try {
      final configModel = AppConfigModel.fromEntity(config);
      await localDataSource.saveAppConfig(configModel);
    } catch (e) {
      throw Exception('Error al guardar configuración local de tickets: $e');
    }
  }

  @override
  Future<void> deleteAppConfig() async {
    try {
      await localDataSource.deleteAppConfig();
    } catch (e) {
      throw Exception('Error al eliminar configuración de tickets: $e');
    }
  }
}
