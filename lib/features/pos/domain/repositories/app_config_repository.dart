import 'package:punto_venta_app/features/pos/domain/entities/app_config.dart';

abstract class AppConfigRepository {
  Future<AppConfig?> getAppConfig();
  Future<AppConfig> fetchAppConfig();
  Future<AppConfig> updateAppConfig(AppConfig config);
  Future<void> saveAppConfigLocally(AppConfig config);
  Future<void> deleteAppConfig();
}
