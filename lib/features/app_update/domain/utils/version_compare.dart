/// Compares semantic versions like `1.0.12`.
/// Prefer [evaluateUpdateAvailability] (build numbers) for update checks.
bool isVersionNewer({
  required String remoteVersion,
  required String localVersion,
  int? remoteBuild,
  int? localBuild,
}) {
  final remoteParts = _parseVersion(remoteVersion);
  final localParts = _parseVersion(localVersion);

  for (var i = 0; i < 3; i++) {
    final r = remoteParts[i];
    final l = localParts[i];
    if (r > l) return true;
    if (r < l) return false;
  }

  if (remoteBuild != null && localBuild != null) {
    return remoteBuild > localBuild;
  }

  return false;
}

List<int> _parseVersion(String version) {
  final cleaned = version.split('+').first.trim();
  final parts = cleaned.split('.');
  return [
    parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
    parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
  ];
}
