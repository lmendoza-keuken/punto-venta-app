import 'package:equatable/equatable.dart';

class AppRelease extends Equatable {
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

  const AppRelease({
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

  AppRelease copyWith({
    String? id,
    String? version,
    int? buildNumber,
    String? downloadUrl,
    String? fileName,
    String? sha256,
    bool? mandatory,
    int? minSupportedBuildVersion,
    String? releaseNotes,
    String? publishedAt,
  }) {
    return AppRelease(
      id: id ?? this.id,
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      fileName: fileName ?? this.fileName,
      sha256: sha256 ?? this.sha256,
      mandatory: mandatory ?? this.mandatory,
      minSupportedBuildVersion:
          minSupportedBuildVersion ?? this.minSupportedBuildVersion,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        version,
        buildNumber,
        downloadUrl,
        fileName,
        sha256,
        mandatory,
        minSupportedBuildVersion,
        releaseNotes,
        publishedAt,
      ];
}
