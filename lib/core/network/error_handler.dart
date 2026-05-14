import 'package:dio/dio.dart';

class ErrorHandler {
  static String handleError(Object error, {String? defaultMessage}) {
    if (error is DioException) {
      // Verificar si hay una respuesta con datos que sea un Map
      if (error.response?.data is Map) {
        final data = error.response!.data as Map;
        // Obtener el campo 'detail' si existe
        if (data.containsKey('detail') && data['detail'] != null) {
          return data['detail'].toString();
        }
      }

      // Manejo de tipos específicos de DioException
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Timeout al conectar con el servidor. Verifica tu conexión.';
        case DioExceptionType.connectionError:
          return 'Error de red. Verifica que el servidor esté disponible.';
        case DioExceptionType.badResponse:
          return defaultMessage ?? 'Error del servidor: ${error.response?.statusCode}';
        default:
          return defaultMessage ?? error.message ?? 'Error inesperado de red';
      }
    }
    
    return defaultMessage ?? error.toString();
  }
}
