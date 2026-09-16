import 'package:punto_venta_app/features/app_update/domain/entities/app_release.dart';

abstract class AppUpdateRepository {
  Future<AppRelease?> fetchLatestRelease();

  /// Downloads [release] to a temp path, verifies SHA-256, launches the installer.
  /// [onProgress] receives values from 0.0 to 1.0.
  Future<void> downloadAndInstall(
    AppRelease release, {
    void Function(double progress)? onProgress,
  });
}
