import 'package:punto_venta_app/features/pos/data/datasources/tax_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/tax_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/tax_model.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/tax_repository.dart';


class TaxRepositoryImpl implements TaxRepository {
  final TaxLocalDataSource localDataSource;
  final TaxRemoteDataSource remoteDataSource;

  TaxRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<TaxModel>> getTaxes() async {
    try {
      final taxes = await remoteDataSource.getTaxes();
      await localDataSource.cacheTaxes(taxes);
      return taxes;
    } catch (e) {
      print('Error al cargar impuestos del backend: $e');
      print('Cargando impuestos desde cache local...');
      
      final cachedTaxes = await localDataSource.getCachedTaxes();
      if (cachedTaxes != null && cachedTaxes.isNotEmpty) {
        return cachedTaxes;
      }
      
      throw Exception('No se pudieron cargar los impuestos: $e');
    }
  }
}
