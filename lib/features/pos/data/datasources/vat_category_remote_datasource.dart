import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import '../models/vat_category_model.dart';

abstract class VatCategoryRemoteDataSource {
  Future<List<VatCategoryModel>> getVatCategories();
}

class VatCategoryRemoteDataSourceImpl implements VatCategoryRemoteDataSource {
  final Dio _dio;
  final Duration timeout;

  VatCategoryRemoteDataSourceImpl({
    Dio? dio,
    this.timeout = const Duration(seconds: 15),
  }) : _dio = dio ?? DioClient.instance;

  @override
  Future<List<VatCategoryModel>> getVatCategories() async {
    final url = ApiConfig.vatCategoriesUrl;

    if (url.isEmpty) {
      throw Exception('URL del endpoint de VAT categories no configurada');
    }

    final localDs = di.sl<AuthLocalDataSource>();
    final token = await localDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación disponible');
    }

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data as List<dynamic>;
        return jsonList
            .map((json) => VatCategoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Error al obtener VAT categories: ${response.statusCode} - ${response.data}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Timeout al intentar conectar con el servidor (VAT categories)');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión al servidor (VAT categories)');
      }
      throw Exception('Error al obtener VAT categories: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al obtener VAT categories: $e');
    }
  }
}
