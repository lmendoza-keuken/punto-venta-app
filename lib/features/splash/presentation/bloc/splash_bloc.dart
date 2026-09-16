import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/update_check_result.dart';
import 'package:punto_venta_app/features/app_update/domain/usecases/check_for_update_usecase.dart';
import 'package:punto_venta_app/features/app_update/domain/utils/app_update_error.dart';
import 'package:punto_venta_app/features/splash/presentation/bloc/splash_event.dart';
import 'package:punto_venta_app/features/splash/presentation/bloc/splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  static const Duration _splashDelay = Duration(seconds: 2);
  static const Duration _updateCheckTimeout = Duration(seconds: 20);

  final CheckForUpdateUseCase? checkForUpdate;

  SplashBloc({this.checkForUpdate}) : super(SplashInitial()) {
    on<StartSplash>(_onStartSplash);
    on<ContinueAfterUpdatePrompt>(_onContinueAfterUpdatePrompt);
  }

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  Future<void> _onStartSplash(
    StartSplash event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashLoading());

    if (!_isWindows || checkForUpdate == null) {
      AppLogger.info(
        'AppUpdate: splash skip check '
        'isWindows=$_isWindows hasUseCase=${checkForUpdate != null}',
      );
      await Future<void>.delayed(_splashDelay);
      emit(SplashCompleted());
      return;
    }

    AppLogger.info(
      'AppUpdate: splash check start timeoutMs=${_updateCheckTimeout.inMilliseconds}',
    );
    final checkSw = Stopwatch()..start();
    final Future<UpdateCheckResult> updateFuture =
        checkForUpdate!().timeout(_updateCheckTimeout);

    await Future<void>.delayed(_splashDelay);

    try {
      final result = await updateFuture;

      AppLogger.info(
        'AppUpdate: splash result available=${result.updateAvailable} '
        'local=${result.currentVersion}+${result.currentBuildNumber} '
        'remoteBuild=${result.release?.buildNumber} '
        'mandatory=${result.release?.mandatory} '
        'elapsedMs=${checkSw.elapsedMilliseconds}',
      );

      if (result.updateAvailable && result.release != null) {
        emit(SplashUpdateAvailable(
          release: result.release!,
          currentVersion: result.currentVersion,
        ));
        return;
      }

      AppLogger.info(
        'AppUpdate: splash no dialog reason='
        '${result.release == null ? "sin_release_usable" : "build_local_al_dia"} '
        'elapsedMs=${checkSw.elapsedMilliseconds}',
      );
    } catch (e, stackTrace) {
      logAppUpdateFailure(
        'splashCheck',
        e,
        stackTrace,
        elapsedMs: checkSw.elapsedMilliseconds,
      );
      AppLogger.info('AppUpdate: continuing to login after check failure');
    }

    emit(SplashCompleted());
  }

  void _onContinueAfterUpdatePrompt(
    ContinueAfterUpdatePrompt event,
    Emitter<SplashState> emit,
  ) {
    emit(SplashCompleted());
  }
}
