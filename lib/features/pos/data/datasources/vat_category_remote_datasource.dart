import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import '../models/vat_category_model.dart';

part 'vat_category_remote_datasource.g.dart';

@RestApi()
abstract class VatCategoryService {
  factory VatCategoryService(Dio dio, {String baseUrl}) = _VatCategoryService;

  @GET('/vat-categories/')
  Future<List<VatCategoryModel>> getVatCategories();
}

abstract class VatCategoryRemoteDataSource {
  Future<List<VatCategoryModel>> getVatCategories();
}

class VatCategoryRemoteDataSourceImpl implements VatCategoryRemoteDataSource {
  VatCategoryService get _apiService => di.sl<VatCategoryService>();

  VatCategoryRemoteDataSourceImpl();

  @override
  Future<List<VatCategoryModel>> getVatCategories() async {
    try {
      return await _apiService.getVatCategories();
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener VAT categories'));
    }
  }
}
