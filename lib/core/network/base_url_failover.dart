import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class BaseUrlFailover {
  BaseUrlFailover._();

  static bool isUnreachable(Object error) {
    if (error is! DioException) return false;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }

  /// Runs [action], rotating baseUrl and retrying on timeout/connection errors.
  static Future<T> runWithFailover<T>(Future<T> Function() action) async {
    final attempted = <String>{};
    final overallSw = Stopwatch()..start();

    while (true) {
      final currentUrl = ApiConfig.activeBaseUrl;
      attempted.add(currentUrl);
      final attemptSw = Stopwatch()..start();

      try {
        final result = await action();
        attemptSw.stop();
        overallSw.stop();
        AppLogger.info(
          'BaseUrlFailover: success '
          'baseUrl=$currentUrl '
          'attemptElapsedMs=${attemptSw.elapsedMilliseconds} '
          'totalElapsedMs=${overallSw.elapsedMilliseconds} '
          'attempts=${attempted.length} '
          'urlChanged=${attempted.length > 1}',
        );
        return result;
      } catch (e) {
        attemptSw.stop();
        if (!isUnreachable(e)) {
          AppLogger.warn(
            'BaseUrlFailover: non-retryable error on $currentUrl '
            'elapsedMs=${attemptSw.elapsedMilliseconds} '
            'error=$e',
          );
          rethrow;
        }

        AppLogger.warn(
          'BaseUrlFailover: unreachable on $currentUrl '
          'elapsedMs=${attemptSw.elapsedMilliseconds}, '
          'trying next URL... attempted=$attempted',
        );

        final previousUrl = currentUrl;
        final switched = ApiConfig.switchToNextBaseUrl();
        if (!switched || attempted.contains(ApiConfig.activeBaseUrl)) {
          overallSw.stop();
          AppLogger.error(
            'BaseUrlFailover: no more URLs to try '
            'lastUrl=$previousUrl '
            'totalElapsedMs=${overallSw.elapsedMilliseconds} '
            'attempted=$attempted',
          );
          rethrow;
        }

        final nextUrl = ApiConfig.activeBaseUrl;
        await _persistActiveBaseUrl(nextUrl);
        AppLogger.info(
          'BaseUrlFailover: URL changed '
          'from=$previousUrl '
          'to=$nextUrl '
          'attempt=${attempted.length + 1}',
        );
      }
    }
  }

  static Future<void> _persistActiveBaseUrl(String newUrl) async {
    try {
      final localDs = di.sl<AuthLocalDataSource>();
      final enterprise = await localDs.getCachedEnterprise();
      if (enterprise == null) return;

      await localDs.cacheEnterprise(
        enterprise.copyWith(baseUrl: newUrl),
      );
    } catch (e, stack) {
      AppLogger.error(
        'BaseUrlFailover: failed to persist active baseUrl',
        e,
        stack,
      );
    }
  }
}
