import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/update_check_result.dart';
import 'package:punto_venta_app/features/app_update/domain/usecases/check_for_update_usecase.dart';
import 'package:punto_venta_app/features/app_update/domain/utils/comprobante_update_threshold.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';

/// After each successful sale, increments a local comprobante counter.
/// When the counter reaches [PdvConfig.checkUpdatePeriod], checks Firestore
/// for a newer Windows release (same path as splash).
class TrackComprobanteAndMaybeCheckUpdateUseCase {
  static const String counterKey = 'COMPROBANTE_UPDATE_CHECK_COUNT';
  static const Duration checkTimeout = Duration(seconds: 8);

  final SharedPreferences sharedPreferences;
  final PdvLocalDataSource pdvLocalDataSource;
  final CheckForUpdateUseCase checkForUpdate;

  TrackComprobanteAndMaybeCheckUpdateUseCase({
    required this.sharedPreferences,
    required this.pdvLocalDataSource,
    required this.checkForUpdate,
  });

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Returns an [UpdateCheckResult] only when a check ran and an update exists.
  Future<UpdateCheckResult?> call() async {
    final config = await pdvLocalDataSource.getPdvConfig();
    final threshold = config?.checkUpdatePeriod;
    if (threshold == null || threshold <= 0) {
      return null;
    }

    final nextCount = (sharedPreferences.getInt(counterKey) ?? 0) + 1;
    await sharedPreferences.setInt(counterKey, nextCount);

    AppLogger.info(
      'AppUpdate: comprobante counter=$nextCount / threshold=$threshold',
    );

    if (!shouldCheckUpdateForComprobantes(
      countAfterIncrement: nextCount,
      threshold: threshold,
    )) {
      return null;
    }

    // Reset so we don't hit Firestore on every subsequent sale.
    await sharedPreferences.setInt(counterKey, 0);

    if (!_isWindows) {
      return null;
    }

    try {
      final result = await checkForUpdate().timeout(checkTimeout);
      if (result.updateAvailable && result.release != null) {
        return result;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'AppUpdate: POS comprobante check failed',
        e,
        stackTrace,
      );
    }

    return null;
  }
}
