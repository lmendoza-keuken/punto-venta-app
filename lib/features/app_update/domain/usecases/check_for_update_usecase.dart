import 'package:package_info_plus/package_info_plus.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/update_check_result.dart';
import 'package:punto_venta_app/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:punto_venta_app/features/app_update/domain/utils/update_availability.dart';

class CheckForUpdateUseCase {
  final AppUpdateRepository repository;

  CheckForUpdateUseCase(this.repository);

  Future<UpdateCheckResult> call() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final currentBuild = packageInfo.buildNumber;
    final localBuild = int.tryParse(currentBuild) ?? 0;

    final release = await repository.fetchLatestRelease();
    if (release == null) {
      AppLogger.info('AppUpdate: no release document found');
      return UpdateCheckResult(
        updateAvailable: false,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuild,
      );
    }

    final availability = evaluateUpdateAvailability(
      localBuild: localBuild,
      remoteBuildNumber: release.buildNumber,
      minSupportedBuildVersion: release.minSupportedBuildVersion,
      mandatoryFlag: release.mandatory,
    );

    AppLogger.info(
      'AppUpdate: local=$currentVersion+$localBuild '
      'remote=${release.version}+${release.buildNumber} '
      'minSupported=${release.minSupportedBuildVersion} '
      'available=${availability.updateAvailable} '
      'forced=${availability.forced}',
    );

    if (!availability.updateAvailable) {
      return UpdateCheckResult(
        updateAvailable: false,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuild,
      );
    }

    return UpdateCheckResult(
      updateAvailable: true,
      release: release.copyWith(mandatory: availability.forced),
      currentVersion: currentVersion,
      currentBuildNumber: currentBuild,
    );
  }
}
