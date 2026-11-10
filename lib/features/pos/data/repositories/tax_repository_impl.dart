import 'package:punto_venta_app/core/utils/app_logger.dart';
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
  Future<List<TaxModel>> getCachedTaxes() async {
    final cached = await localDataSource.getCachedTaxes();
    return cached ?? const <TaxModel>[];
  }

  @override
  Future<List<TaxModel>> getTaxes({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localDataSource.getCachedTaxes();
      if (cached != null && cached.isNotEmpty) {
        AppLogger.info(
          'TaxRepo: cache hit count=${cached.length} forceRefresh=false',
        );
        return cached;
      }
      AppLogger.info('TaxRepo: cache miss — fetching remote');
    } else {
      AppLogger.info('TaxRepo: forceRefresh — fetching remote');
    }

    final sw = Stopwatch()..start();
    try {
      final taxes = await remoteDataSource.getTaxes();
      await localDataSource.cacheTaxes(taxes);
      sw.stop();
      AppLogger.info(
        'TaxRepo: remote ok count=${taxes.length} '
        'elapsedMs=${sw.elapsedMilliseconds}',
      );
      return taxes;
    } catch (e) {
      sw.stop();
      AppLogger.warn(
        'TaxRepo: remote fail elapsedMs=${sw.elapsedMilliseconds} error=$e',
      );

      final cachedTaxes = await localDataSource.getCachedTaxes();
      if (cachedTaxes != null && cachedTaxes.isNotEmpty) {
        AppLogger.info(
          'TaxRepo: fallback cache count=${cachedTaxes.length}',
        );
        return cachedTaxes;
      }

      throw Exception('No se pudieron cargar los impuestos: $e');
    }
  }
}
