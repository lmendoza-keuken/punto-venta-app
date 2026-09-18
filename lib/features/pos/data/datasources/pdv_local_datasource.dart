import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';

abstract class PdvLocalDataSource {
  Future<PdvConfig?> getPdvConfig();
  Future<void> savePdvConfig(PdvConfig config);
}

class PdvLocalDataSourceImpl implements PdvLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _key = 'PDV_CONFIG';

  PdvLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<PdvConfig?> getPdvConfig() async {
    final jsonString = sharedPreferences.getString(_key);
    if (jsonString == null) {
      AppLogger.info('PdvLocal: getPdvConfig key=$_key → null (sin cache)');
      return null;
    }
    try {
      final Map<String, dynamic> data =
          json.decode(jsonString) as Map<String, dynamic>;
      final config = PdvConfig.fromJson(data);
      AppLogger.info(
        'PdvLocal: getPdvConfig ok pdvId=${config.pdvId} '
        'branchId=${config.branchId} offlineMode=${config.offlineMode} '
        'rawLen=${jsonString.length}',
      );
      return config;
    } catch (e, stackTrace) {
      AppLogger.error(
        'PdvLocal: getPdvConfig parse falló raw=$jsonString',
        e,
        stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> savePdvConfig(PdvConfig config) async {
    final jsonString = json.encode(config.toJson());
    AppLogger.info(
      'PdvLocal: savePdvConfig start pdvId=${config.pdvId} '
      'branchId=${config.branchId} offlineMode=${config.offlineMode} '
      'json=$jsonString',
    );
    final ok = await sharedPreferences.setString(_key, jsonString);
    final verify = sharedPreferences.getString(_key);
    AppLogger.info(
      'PdvLocal: savePdvConfig done setStringOk=$ok '
      'verifyLen=${verify?.length} verifyMatch=${verify == jsonString}',
    );
    if (!ok || verify != jsonString) {
      AppLogger.warn(
        'PdvLocal: savePdvConfig verificación falló setStringOk=$ok '
        'verify=$verify',
      );
    }
  }
}
