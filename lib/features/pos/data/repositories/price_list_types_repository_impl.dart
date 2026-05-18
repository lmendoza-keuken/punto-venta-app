import 'package:punto_venta_app/features/pos/data/datasources/price_list_types_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_types_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/price_list_type_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/price_list_types_repository.dart';

class PriceListTypesRepositoryImpl implements PriceListTypesRepository {
  final PriceListTypesRemoteDataSource remoteDataSource;
  final PriceListTypesLocalDataSource localDataSource;

  PriceListTypesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });


  @override
  Future<List<PriceListTypeResponseModel>> fetchPriceListTypes() async {
    final localConfig = await localDataSource.getCachedPriceListTypes();

    try {
      if (localConfig != null) {
        return localConfig;
      }

      final priceListTypes = await remoteDataSource.fetchPriceListTypes();

      await localDataSource.cachePriceListTypes(priceListTypes);

      return priceListTypes;
    } catch (e) {
      if (localConfig != null) {
        return localConfig;
      }
      throw Exception('Error al obtener tipos de lista de precios: $e');
    }
  }
}
