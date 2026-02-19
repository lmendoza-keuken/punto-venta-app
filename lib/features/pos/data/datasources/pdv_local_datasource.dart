import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
      return null;
    }
    try {
      final Map<String, dynamic> data = json.decode(jsonString) as Map<String, dynamic>;
      return PdvConfig.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> savePdvConfig(PdvConfig config) async {
    final jsonString = json.encode(config.toJson());
    await sharedPreferences.setString(_key, jsonString);
  }
}
