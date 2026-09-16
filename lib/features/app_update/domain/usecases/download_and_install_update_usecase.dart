import 'package:punto_venta_app/features/app_update/domain/entities/app_release.dart';
import 'package:punto_venta_app/features/app_update/domain/repositories/app_update_repository.dart';

class DownloadAndInstallUpdateUseCase {
  final AppUpdateRepository repository;

  DownloadAndInstallUpdateUseCase(this.repository);

  Future<void> call(
    AppRelease release, {
    void Function(double progress)? onProgress,
  }) {
    return repository.downloadAndInstall(release, onProgress: onProgress);
  }
}
