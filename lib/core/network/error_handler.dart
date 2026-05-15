import 'package:dio/dio.dart';

class ErrorHandler {
  static String handleError(Object error, {String? defaultMessage}) {
    if (error is DioException) {
      // Verificar si hay una respuesta con datos
      if (error.response?.data != null) {
        final data = error.response!.data;
        
        if (data is Map) {
          // Obtener el campo 'detail', 'message' o 'error' si existen
          if (data.containsKey('detail') && data['detail'] != null) {
            return data['detail'].toString();
          }
          if (data.containsKey('message') && data['message'] != null) {
            return data['message'].toString();
          }
          if (data.containsKey('error') && data['error'] != null) {
            return data['error'].toString();
          }
        } else if (data is String && data.isNotEmpty) {
          return data;
        }
      }

      // Manejo de tipos específicos de DioException
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Tiempo de espera agotado. Verifica tu conexión a internet.';
        case DioExceptionType.connectionError:
          return 'Error de conexión. Verifica que el servidor esté disponible.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401 || statusCode == 403) {
            return 'No autorizado. Por favor, inicia sesión de nuevo.';
          }
          if (statusCode == 404) {
            return 'Recurso no encontrado en el servidor.';
          }
          if (statusCode != null && statusCode >= 500) {
            return 'Error interno del servidor. Por favor, intenta más tarde.';
          }
          return defaultMessage ?? 'Error del servidor: $statusCode';
        default:
          return defaultMessage ?? error.message ?? 'Error inesperado de red';
      }
    }
    
    // Si no es DioException, retornar el mensaje por defecto o el error
    if (error is Exception) {
      final msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        return msg.replaceFirst('Exception: ', '');
      }
      return msg;
    }
    
    return defaultMessage ?? error.toString();
  }
}
