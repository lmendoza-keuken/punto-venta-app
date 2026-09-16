import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/update_check_result.dart';
import 'package:punto_venta_app/features/app_update/domain/usecases/check_for_update_usecase.dart';
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

    final Future<UpdateCheckResult>? updateFuture =
        (_isWindows && checkForUpdate != null)
            ? checkForUpdate!().timeout(_updateCheckTimeout)
            : null;

    await Future<void>.delayed(_splashDelay);

    if (updateFuture == null) {
      AppLogger.info(
        'AppUpdate: splash skip check '
        'isWindows=$_isWindows hasUseCase=${checkForUpdate != null}',
      );
      emit(SplashCompleted());
      return;
    }

    try {
      final result = await updateFuture;

      AppLogger.info(
        'AppUpdate: splash result available=${result.updateAvailable} '
        'local=${result.currentVersion}+${result.currentBuildNumber} '
        'remoteBuild=${result.release?.buildNumber} '
        'mandatory=${result.release?.mandatory}',
      );

      if (result.updateAvailable && result.release != null) {
        emit(SplashUpdateAvailable(
          release: result.release!,
          currentVersion: result.currentVersion,
        ));
        return;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'AppUpdate: check failed, continuing to login',
        e,
        stackTrace,
      );
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
