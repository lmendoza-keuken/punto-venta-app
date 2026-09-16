import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/app_release.dart';

abstract class UpdateDownloader {
  Future<File> download(
    AppRelease release, {
    void Function(double progress)? onProgress,
  });

  Future<void> verifySha256(File file, String expectedSha256);

  Future<void> launchInstaller(File setupFile);
}

class UpdateDownloaderImpl implements UpdateDownloader {
  /// Dedicated Dio without API interceptors / company baseUrl.
  Dio _createDownloadDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 30),
        sendTimeout: const Duration(minutes: 5),
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
  }

  @override
  Future<File> download(
    AppRelease release, {
    void Function(double progress)? onProgress,
  }) async {
    final dio = _createDownloadDio();
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, release.fileName);
      final file = File(targetPath);

      if (await file.exists()) {
        await file.delete();
      }

      AppLogger.info('AppUpdate: downloading ${release.downloadUrl} -> $targetPath');

      await dio.download(
        release.downloadUrl,
        targetPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      onProgress?.call(1.0);
      return file;
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<void> verifySha256(File file, String expectedSha256) async {
    final expected = expectedSha256.trim().toLowerCase();
    if (expected.isEmpty) {
      AppLogger.info('AppUpdate: sha256 vacío, se omite verificación');
      return;
    }

    final digest = await sha256.bind(file.openRead()).first;
    final actual = digest.toString().toLowerCase();

    AppLogger.info('AppUpdate: sha256 expected=$expected actual=$actual');

    if (actual != expected) {
      try {
        await file.delete();
      } catch (_) {}
      throw Exception(
        'El instalador descargado no coincide con el hash esperado. '
        'Volvé a intentar o contactá soporte.',
      );
    }
  }

  @override
  Future<void> launchInstaller(File setupFile) async {
    if (!Platform.isWindows) {
      throw UnsupportedError('Installer launch is only supported on Windows');
    }

    AppLogger.info('AppUpdate: launching installer ${setupFile.path}');

    await Process.start(
      setupFile.path,
      const ['/SILENT', '/CLOSEAPPLICATIONS', '/NORESTART', '/VERYSILENT'],
      mode: ProcessStartMode.detached,
      runInShell: false,
    );
  }
}
