import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';

abstract class UserApiDataSource {
  Future<Map<String, dynamic>> authenticateUser(String userId, String password);
}

class UserApiDataSourceImpl implements UserApiDataSource {
  final Dio _dio;

  UserApiDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  String _encode(String s) {
    return String.fromCharCodes(s.runes.map((r) => r - 9));
  }

  @override
  Future<Map<String, dynamic>> authenticateUser(
      String userId, String password) async {
    try {
     

      final encodedPassword = _encode(password);

      final response = await _dio.post(
        ApiConfig.loginUrl,
        data: {
          'id': userId,
          'password': encodedPassword,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;

        return {
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Error al autenticar: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Tiempo de conexión agotado');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Tiempo de respuesta agotado');
      } else if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403) {
        throw Exception('Credenciales inválidas');
      } else if (e.response != null) {
        throw Exception(
            'Error del servidor: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error al autenticar usuario: $e');
    }
  }
}
