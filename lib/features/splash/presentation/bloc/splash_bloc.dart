import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/app_update/domain/usecases/check_for_update_usecase.dart';
import 'package:punto_venta_app/features/splash/presentation/bloc/splash_event.dart';
import 'package:punto_venta_app/features/splash/presentation/bloc/splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
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

    await Future<void>.delayed(const Duration(seconds: 2));

    if (!_isWindows || checkForUpdate == null) {
      emit(SplashCompleted());
      return;
    }

    try {
      final result =
          await checkForUpdate!().timeout(const Duration(seconds: 8));

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
