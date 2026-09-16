import 'package:punto_venta_app/features/app_update/domain/entities/app_release.dart';

class UpdateCheckResult {
  final bool updateAvailable;
  final AppRelease? release;
  final String currentVersion;
  final String? currentBuildNumber;

  const UpdateCheckResult({
    required this.updateAvailable,
    required this.currentVersion,
    this.release,
    this.currentBuildNumber,
  });
}
