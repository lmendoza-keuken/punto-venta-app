import 'package:punto_venta_app/features/pos/domain/entities/app_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/app_config_repository.dart';

class UpdateAppConfigUsecase {
  final AppConfigRepository repository;

  UpdateAppConfigUsecase(this.repository);

  Future<AppConfig> call(AppConfig config) async {
    return await repository.updateAppConfig(config);
  }
}
