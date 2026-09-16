import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/app_release.dart';

enum AppUpdateStatus {
  idle,
  downloading,
  verifying,
  launching,
  error,
}

class AppUpdateState extends Equatable {
  final AppUpdateStatus status;
  final double progress;
  final String? errorMessage;
  final AppRelease? release;

  const AppUpdateState({
    this.status = AppUpdateStatus.idle,
    this.progress = 0,
    this.errorMessage,
    this.release,
  });

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    double? progress,
    String? errorMessage,
    AppRelease? release,
    bool clearError = false,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      release: release ?? this.release,
    );
  }

  @override
  List<Object?> get props => [status, progress, errorMessage, release];
}
