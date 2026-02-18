import 'package:punto_venta_app/features/pos/domain/entities/app_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/app_config_repository.dart';

class GetAppConfigUsecase {
  final AppConfigRepository repository;

  GetAppConfigUsecase(this.repository);

  Future<AppConfig?> call() async {
    return await repository.getAppConfig();
  }
}
