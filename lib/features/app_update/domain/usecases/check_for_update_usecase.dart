import 'package:package_info_plus/package_info_plus.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/update_check_result.dart';
import 'package:punto_venta_app/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:punto_venta_app/features/app_update/domain/utils/app_update_error.dart';
import 'package:punto_venta_app/features/app_update/domain/utils/update_availability.dart';

class CheckForUpdateUseCase {
  final AppUpdateRepository repository;

  CheckForUpdateUseCase(this.repository);

  Future<UpdateCheckResult> call() async {
    final totalSw = Stopwatch()..start();
    String currentVersion = '';
    String currentBuild = '';
    var localBuild = 0;

    try {
      AppLogger.info('AppUpdate: stage=packageInfo start');
      final packageSw = Stopwatch()..start();
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
      currentBuild = packageInfo.buildNumber;
      localBuild = int.tryParse(currentBuild) ?? 0;
      AppLogger.info(
        'AppUpdate: stage=packageInfo done elapsedMs=${packageSw.elapsedMilliseconds} '
        'version=$currentVersion build=$currentBuild localBuild=$localBuild '
        'packageName=${packageInfo.packageName}',
      );
    } catch (e, stackTrace) {
      logAppUpdateFailure(
        'packageInfo',
        e,
        stackTrace,
        elapsedMs: totalSw.elapsedMilliseconds,
      );
      rethrow;
    }

    try {
      AppLogger.info('AppUpdate: stage=fetchRelease start');
      final fetchSw = Stopwatch()..start();
      final release = await repository.fetchLatestRelease();
      AppLogger.info(
        'AppUpdate: stage=fetchRelease done elapsedMs=${fetchSw.elapsedMilliseconds} '
        'found=${release != null}',
      );

      if (release == null) {
        AppLogger.info(
          'AppUpdate: outcome=no_release '
          '(doc ausente, 404, o version/downloadUrl vacíos) '
          'totalMs=${totalSw.elapsedMilliseconds}',
        );
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
        'AppUpdate: stage=compare '
        'localBuild=$localBuild remoteBuild=${release.buildNumber} '
        'minSupported=${release.minSupportedBuildVersion} '
        'mandatoryFlag=${release.mandatory} '
        'available=${availability.updateAvailable} '
        'forced=${availability.forced} '
        'totalMs=${totalSw.elapsedMilliseconds}',
      );

      if (!availability.updateAvailable) {
        AppLogger.info(
          'AppUpdate: outcome=up_to_date '
          'localBuild=$localBuild remoteBuild=${release.buildNumber}',
        );
        return UpdateCheckResult(
          updateAvailable: false,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuild,
        );
      }

      AppLogger.info(
        'AppUpdate: outcome=update_available forced=${availability.forced}',
      );
      return UpdateCheckResult(
        updateAvailable: true,
        release: release.copyWith(mandatory: availability.forced),
        currentVersion: currentVersion,
        currentBuildNumber: currentBuild,
      );
    } catch (e, stackTrace) {
      logAppUpdateFailure(
        'fetchOrCompare',
        e,
        stackTrace,
        elapsedMs: totalSw.elapsedMilliseconds,
      );
      rethrow;
    }
  }
}
