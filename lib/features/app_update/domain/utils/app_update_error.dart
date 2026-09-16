import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';

/// Classifies AppUpdate failures so logs show the real cause (not only timeout).
class AppUpdateErrorInfo {
  final String kind;
  final String hint;

  const AppUpdateErrorInfo(this.kind, this.hint);

  @override
  String toString() => 'kind=$kind hint=$hint';
}

AppUpdateErrorInfo classifyAppUpdateError(Object error) {
  if (error is TimeoutException) {
    return const AppUpdateErrorInfo(
      'TimeoutException',
      'La red/Firestore no respondió a tiempo',
    );
  }
  if (error is SocketException) {
    return AppUpdateErrorInfo(
      'SocketException',
      'Sin conexión o host bloqueado: ${error.message}',
    );
  }
  if (error is HandshakeException) {
    return const AppUpdateErrorInfo(
      'HandshakeException',
      'Fallo TLS/SSL hacia el servidor',
    );
  }
  if (error is HttpException) {
    return AppUpdateErrorInfo(
      'HttpException',
      'HTTP inválido: ${error.message}',
    );
  }
  if (error is FormatException) {
    return const AppUpdateErrorInfo(
      'FormatException',
      'Respuesta JSON/Firestore malformada',
    );
  }
  if (error is FirebaseException) {
    return AppUpdateErrorInfo(
      'FirebaseException(${error.code})',
      error.message ?? 'Error Firebase',
    );
  }
  if (error is PathAccessException || error is PathNotFoundException) {
    return AppUpdateErrorInfo(
      error.runtimeType.toString(),
      'Problema de archivo/permisos locales',
    );
  }
  if (error is ProcessException) {
    return AppUpdateErrorInfo(
      'ProcessException',
      'No se pudo lanzar el instalador: ${error.message}',
    );
  }
  if (error is UnsupportedError) {
    return const AppUpdateErrorInfo(
      'UnsupportedError',
      'Operación no soportada en esta plataforma',
    );
  }

  final text = error.toString();
  if (text.contains('HTTP 401') || text.contains('HTTP 403')) {
    return const AppUpdateErrorInfo(
      'AuthHttpError',
      'Token inválido o reglas Firestore denegaron la lectura',
    );
  }
  if (text.contains('HTTP 404')) {
    return const AppUpdateErrorInfo(
      'NotFoundHttpError',
      'Documento appVersionsInfo/punto_venta no existe',
    );
  }
  if (text.contains('HTTP ')) {
    return AppUpdateErrorInfo(
      'HttpStatusError',
      text.length > 180 ? '${text.substring(0, 180)}…' : text,
    );
  }

  return AppUpdateErrorInfo(
    error.runtimeType.toString(),
    text.length > 180 ? '${text.substring(0, 180)}…' : text,
  );
}

void logAppUpdateFailure(
  String stage,
  Object error,
  StackTrace stackTrace, {
  int? elapsedMs,
}) {
  final info = classifyAppUpdateError(error);
  final elapsed = elapsedMs != null ? ' elapsedMs=$elapsedMs' : '';
  AppLogger.error(
    'AppUpdate: FAIL stage=$stage ${info.kind} hint=${info.hint}$elapsed',
    error,
    stackTrace,
  );
}
