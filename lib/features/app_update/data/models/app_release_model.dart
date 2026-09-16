import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/app_release.dart';

class AppReleaseModel {
  final String id;
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String fileName;
  final String sha256;
  final bool mandatory;
  final int minSupportedBuildVersion;
  final String? releaseNotes;
  final String? publishedAt;

  const AppReleaseModel({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.fileName,
    this.id = 'punto_venta',
    this.sha256 = '',
    this.mandatory = false,
    this.minSupportedBuildVersion = 0,
    this.releaseNotes,
    this.publishedAt,
  });

  factory AppReleaseModel.fromMap(Map<String, dynamic> data) {
    final version = data['version']?.toString() ?? '';
    final rawDownload = data['downloadUrl']?.toString().trim() ?? '';
    final fallbackUrl = data['url']?.toString().trim() ?? '';
    final downloadUrl = rawDownload.isNotEmpty ? rawDownload : fallbackUrl;

    final fileName = data['fileName']?.toString().isNotEmpty == true
        ? data['fileName'].toString()
        : _fileNameFromUrl(downloadUrl, version);

    return AppReleaseModel(
      id: data['id']?.toString() ?? 'punto_venta',
      version: version,
      buildNumber: _asInt(data['buildNumber']),
      downloadUrl: downloadUrl,
      fileName: fileName,
      sha256: data['sha256']?.toString() ?? '',
      mandatory: data['mandatory'] == true,
      minSupportedBuildVersion: _asInt(data['minSupportedBuildVersion']),
      releaseNotes: data['releaseNotes']?.toString(),
      publishedAt: _publishedAtToString(data['publishedAt']),
    );
  }

  AppRelease toEntity() {
    return AppRelease(
      id: id,
      version: version,
      buildNumber: buildNumber,
      downloadUrl: downloadUrl,
      fileName: fileName,
      sha256: sha256,
      mandatory: mandatory,
      minSupportedBuildVersion: minSupportedBuildVersion,
      releaseNotes: releaseNotes,
      publishedAt: publishedAt,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _publishedAtToString(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _fileNameFromUrl(String url, String version) {
    try {
      final uri = Uri.parse(url);
      final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      final decoded = Uri.decodeComponent(last);
      if (decoded.toLowerCase().endsWith('.exe')) {
        return decoded;
      }
    } catch (_) {}
    return 'PuntoDeVenta-Setup-$version.exe';
  }
}
