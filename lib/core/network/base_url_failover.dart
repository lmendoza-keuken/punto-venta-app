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

    while (true) {
      final currentUrl = ApiConfig.activeBaseUrl;
      attempted.add(currentUrl);

      try {
        return await action();
      } catch (e) {
        if (!isUnreachable(e)) {
          rethrow;
        }

        AppLogger.warn(
          'BaseUrlFailover: unreachable on $currentUrl, trying next URL...',
        );

        final switched = ApiConfig.switchToNextBaseUrl();
        if (!switched || attempted.contains(ApiConfig.activeBaseUrl)) {
          rethrow;
        }

        await _persistActiveBaseUrl(ApiConfig.activeBaseUrl);
        AppLogger.info(
          'BaseUrlFailover: switched to ${ApiConfig.activeBaseUrl}',
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
