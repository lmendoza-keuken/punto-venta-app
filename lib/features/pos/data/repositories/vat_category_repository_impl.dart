import 'package:punto_venta_app/features/pos/data/datasources/vat_category_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/vat_category_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/vat_category_model.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/vat_category_repository.dart';

class VatCategoryRepositoryImpl implements VatCategoryRepository {
  final VatCategoryLocalDataSource localDataSource;
  final VatCategoryRemoteDataSource remoteDataSource;

  VatCategoryRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<VatCategoryModel>> getVatCategories() async {
    try {
      final vatCategories = await remoteDataSource.getVatCategories();
      await localDataSource.cacheVatCategories(vatCategories);
      return vatCategories;
    } catch (e) {
      print('Error al cargar VAT categories del backend: $e');
      print('Cargando VAT categories desde cache local...');
      
      final cachedVatCategories = await localDataSource.getCachedVatCategories();
      if (cachedVatCategories != null && cachedVatCategories.isNotEmpty) {
        return cachedVatCategories;
      }
      
      throw Exception('No se pudieron cargar las VAT categories: $e');
    }
  }
}
