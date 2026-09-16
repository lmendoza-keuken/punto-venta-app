import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/app_release.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}

class SplashLoading extends SplashState {}

class SplashUpdateAvailable extends SplashState {
  final AppRelease release;
  final String currentVersion;

  const SplashUpdateAvailable({
    required this.release,
    required this.currentVersion,
  });

  @override
  List<Object?> get props => [release, currentVersion];
}

class SplashCompleted extends SplashState {}
