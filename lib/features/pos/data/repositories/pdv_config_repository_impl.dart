import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/branch_local_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';
import 'package:punto_venta_app/core/network/exceptions.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';

class PdvConfigRepositoryImpl implements PdvConfigRepository {
  final PdvRemoteDataSource remoteDataSource;
  final PdvLocalDataSource localDataSource;
  final BranchLocalDataSource branchLocalDataSource;

  PdvConfigRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.branchLocalDataSource,
  });

  @override
  Future<PdvConfig> fetchPdvConfig() async {
    AppLogger.info('PdvConfigRepo: fetchPdvConfig start');
    final localConfig = await localDataSource.getPdvConfig();
    AppLogger.info(
      'PdvConfigRepo: local '
      'pdvId=${localConfig?.pdvId} branchId=${localConfig?.branchId} '
      'offlineMode=${localConfig?.offlineMode}',
    );

    try {
      AppLogger.info('PdvConfigRepo: llamando remoto GET /configuration/');
      final data = await remoteDataSource.fetchPdvConfig();
      AppLogger.info(
        'PdvConfigRepo: remoto ok deliveryLocationId=${data.deliveryLocationId} '
        'branchId=${data.branchId} offlineMode=${data.offlineMode} '
        'creditNoteDaysLimit=${data.creditNoteDaysLimit} '
        'checkUpdatePeriod=${data.checkUpdatePeriod}',
      );

      final remoteConfig = PdvConfig(
        pdvId: data.deliveryLocationId,
        branchId: data.branchId,
        offlineMode: data.offlineMode,
        creditNoteDaysLimit: data.creditNoteDaysLimit,
        checkUpdatePeriod: data.checkUpdatePeriod,
      );

      final finalData = PdvConfig(
        pdvId: remoteConfig.pdvId ?? localConfig?.pdvId,
        branchId: remoteConfig.branchId ?? localConfig?.branchId,
        branchNumber: remoteConfig.branchNumber ?? localConfig?.branchNumber,
        offlineMode: remoteConfig.offlineMode ?? localConfig?.offlineMode,
        creditNoteDaysLimit:
            remoteConfig.creditNoteDaysLimit ?? localConfig?.creditNoteDaysLimit,
        checkUpdatePeriod:
            remoteConfig.checkUpdatePeriod ?? localConfig?.checkUpdatePeriod,
      );
      AppLogger.info(
        'PdvConfigRepo: merge final pdvId=${finalData.pdvId} '
        'branchId=${finalData.branchId} offlineMode=${finalData.offlineMode} '
        '(remoto pdvId=${remoteConfig.pdvId} local pdvId=${localConfig?.pdvId})',
      );
      await localDataSource.savePdvConfig(finalData);
      AppLogger.info('PdvConfigRepo: fetchPdvConfig cache actualizado');
      return finalData;
    } catch (e, stackTrace) {
      if (e is NotFoundException) {
        AppLogger.warn('PdvConfigRepo: remoto 404 NotFound — no se actualiza cache');
        rethrow;
      }
      AppLogger.error(
        'PdvConfigRepo: remoto falló, intentando fallback local',
        e,
        stackTrace,
      );
      if (localConfig != null) {
        AppLogger.info(
          'PdvConfigRepo: usando cache local pdvId=${localConfig.pdvId}',
        );
        return localConfig;
      }
      AppLogger.error('PdvConfigRepo: sin cache local, propagando error');
      throw Exception('Error al obtener configuración del PDV: $e');
    }
  }

  @override
  Future<PdvConfig?> getLocalPdvConfig() async {
    return await localDataSource.getPdvConfig();
  }

  @override
  Future<void> savePdvConfig(PdvConfig config) async {
    AppLogger.info(
      'PdvConfigRepo: savePdvConfig remoto+local pdvId=${config.pdvId} '
      'branchId=${config.branchId}',
    );
    await remoteDataSource.updatePdvConfig(config);
    await localDataSource.savePdvConfig(config);
    AppLogger.info('PdvConfigRepo: savePdvConfig ok');
  }

  @override
  Future<void> updateOfflineMode(PdvConfig config) async {
    AppLogger.info(
      'PdvConfigRepo: updateOfflineMode offlineMode=${config.offlineMode} '
      'pdvId=${config.pdvId} branchId=${config.branchId}',
    );
    await remoteDataSource.updateOfflineMode(config);
    await localDataSource.savePdvConfig(config);
    AppLogger.info('PdvConfigRepo: updateOfflineMode ok');
  }

  @override
  Future<List<Branch>> fetchBranches() async {
    try {
      final branches = await remoteDataSource.fetchBranches();
      
      await branchLocalDataSource.cacheBranches(branches);
      
      return branches.map((model) => Branch.fromModel(model)).toList();
    } catch (e) {
      throw Exception('Error al obtener sucursales: $e');
    }
  }
}
