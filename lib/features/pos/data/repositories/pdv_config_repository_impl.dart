import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';

class PdvConfigRepositoryImpl implements PdvConfigRepository {
  final PdvRemoteDataSource remoteDataSource;
  final PdvLocalDataSource localDataSource;

  PdvConfigRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<PdvConfig> fetchPdvConfig() async {
    try {
      final data = await remoteDataSource.fetchPdvConfig();

      final config = PdvConfig(
        pdvId: data.deliveryLocationId,
        branchId: data.branchId,
        offlineMode: data.offlineMode,
      );

      // Obtener el numeroSucursal local si existe
      final localConfig = await localDataSource.getPdvConfig();
      if (localConfig != null) {
        return config.copyWith(branchNumber: localConfig.branchNumber);
      }

      return config;
    } catch (e) {
      final localConfig = await localDataSource.getPdvConfig();
      if (localConfig != null) {
        return localConfig;
      }
      throw Exception('Error al obtener configuración del PDV: $e');
    }
  }

  @override
  Future<PdvConfig?> getLocalPdvConfig() async {
    return await localDataSource.getPdvConfig();
  }

  @override
  Future<void> savePdvConfig(PdvConfig config) async {
    await localDataSource.savePdvConfig(config);
    await remoteDataSource.updatePdvConfig(config);
  }

  @override
  Future<void> updateOfflineMode(PdvConfig config) async {
    await localDataSource.savePdvConfig(config);
    await remoteDataSource.updateOfflineMode(config);
  }

  @override
  Future<List<Branch>> fetchBranches() async {
    try {
      final branches = await remoteDataSource.fetchBranches();
      return branches.map((model) => Branch.fromModel(model)).toList();
    } catch (e) {
      throw Exception('Error al obtener sucursales: $e');
    }
  }
}
