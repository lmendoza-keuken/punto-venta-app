import 'dart:io';

import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/app_update/data/datasources/firestore_update_datasource.dart';
import 'package:punto_venta_app/features/app_update/data/datasources/update_downloader.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/app_release.dart';
import 'package:punto_venta_app/features/app_update/domain/repositories/app_update_repository.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  final FirestoreUpdateDatasource firestoreDatasource;
  final UpdateDownloader downloader;

  AppUpdateRepositoryImpl({
    required this.firestoreDatasource,
    required this.downloader,
  });

  @override
  Future<AppRelease?> fetchLatestRelease() async {
    final model = await firestoreDatasource.fetchWindowsRelease();
    if (model == null) {
      AppLogger.warn('AppUpdate: repository got null model from datasource');
      return null;
    }

    if (model.version.isEmpty || model.downloadUrl.isEmpty) {
      AppLogger.warn(
        'AppUpdate: release incompleto versionEmpty=${model.version.isEmpty} '
        'downloadUrlEmpty=${model.downloadUrl.isEmpty} '
        'buildNumber=${model.buildNumber}',
      );
      return null;
    }

    AppLogger.info(
      'AppUpdate: repository release ok version=${model.version} '
      'build=${model.buildNumber}',
    );
    return model.toEntity();
  }

  @override
  Future<void> downloadAndInstall(
    AppRelease release, {
    void Function(double progress)? onProgress,
  }) async {
    final file = await downloader.download(release, onProgress: onProgress);
    await downloader.verifySha256(file, release.sha256);
    await downloader.launchInstaller(file);

    // Give the installer a moment to start, then exit so files can be replaced.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    exit(0);
  }
}
