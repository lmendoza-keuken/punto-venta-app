import 'package:json_annotation/json_annotation.dart';

enum QrType {
  @JsonValue('MP')
  mp,
  @JsonValue('PVS')
  pvs,
}

QrType? qrTypeFromJson(Object? value) {
  if (value == null) return null;
  final raw = value.toString().toUpperCase();
  switch (raw) {
    case 'MP':
      return QrType.mp;
    case 'PVS':
      return QrType.pvs;
    default:
      return null;
  }
}

String? qrTypeToJson(QrType? value) {
  switch (value) {
    case QrType.mp:
      return 'MP';
    case QrType.pvs:
      return 'PVS';
    case null:
      return null;
  }
}
