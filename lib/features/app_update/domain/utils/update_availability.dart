/// Build-based update decision for [appVersionsInfo/punto_venta].
class UpdateAvailability {
  final bool updateAvailable;
  final bool forced;

  const UpdateAvailability({
    required this.updateAvailable,
    required this.forced,
  });
}

/// Returns whether an update should be offered and if it must be forced.
///
/// - Available when [localBuild] < [remoteBuildNumber].
/// - Forced when available and (
///     [localBuild] < [minSupportedBuildVersion] OR [mandatoryFlag]
///   ).
UpdateAvailability evaluateUpdateAvailability({
  required int localBuild,
  required int remoteBuildNumber,
  required int minSupportedBuildVersion,
  required bool mandatoryFlag,
}) {
  final updateAvailable = localBuild < remoteBuildNumber;
  if (!updateAvailable) {
    return const UpdateAvailability(updateAvailable: false, forced: false);
  }

  final forcedByMin = localBuild < minSupportedBuildVersion;
  return UpdateAvailability(
    updateAvailable: true,
    forced: forcedByMin || mandatoryFlag,
  );
}
