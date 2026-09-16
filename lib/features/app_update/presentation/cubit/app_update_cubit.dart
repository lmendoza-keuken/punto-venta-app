import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/app_release.dart';
import 'package:punto_venta_app/features/app_update/domain/usecases/download_and_install_update_usecase.dart';
import 'package:punto_venta_app/features/app_update/presentation/cubit/app_update_state.dart';

class AppUpdateCubit extends Cubit<AppUpdateState> {
  final DownloadAndInstallUpdateUseCase downloadAndInstallUpdate;

  AppUpdateCubit({
    required this.downloadAndInstallUpdate,
  }) : super(const AppUpdateState());

  Future<void> startUpdate(AppRelease release) async {
    emit(state.copyWith(
      status: AppUpdateStatus.downloading,
      progress: 0,
      release: release,
      clearError: true,
    ));

    try {
      await downloadAndInstallUpdate(
        release,
        onProgress: (progress) {
          if (!isClosed) {
            emit(state.copyWith(
              status: AppUpdateStatus.downloading,
              progress: progress,
            ));
          }
        },
      );
      // Normally the process exits after launching the installer.
      if (!isClosed) {
        emit(state.copyWith(status: AppUpdateStatus.launching, progress: 1));
      }
    } catch (e, stackTrace) {
      AppLogger.error('AppUpdate: download/install failed', e, stackTrace);
      if (!isClosed) {
        emit(state.copyWith(
          status: AppUpdateStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ));
      }
    }
  }

  void reset() {
    emit(const AppUpdateState());
  }
}
