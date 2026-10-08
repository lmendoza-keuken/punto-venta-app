import 'package:shared_preferences/shared_preferences.dart';

abstract class MercadoPagoLocalDataSource {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> saveExternalPosId(String externalPosId);
  Future<String?> getExternalPosId();
  Future<void> clear();
}

class MercadoPagoLocalDataSourceImpl implements MercadoPagoLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const _tokenKey = 'MP_ACCESS_TOKEN';
  static const _externalPosIdKey = 'MP_EXTERNAL_POS_ID';

  MercadoPagoLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> saveAccessToken(String token) async {
    await sharedPreferences.setString(_tokenKey, token);
  }

  @override
  Future<String?> getAccessToken() async {
    return sharedPreferences.getString(_tokenKey);
  }

  @override
  Future<void> saveExternalPosId(String externalPosId) async {
    await sharedPreferences.setString(_externalPosIdKey, externalPosId);
  }

  @override
  Future<String?> getExternalPosId() async {
    return sharedPreferences.getString(_externalPosIdKey);
  }

  @override
  Future<void> clear() async {
    await sharedPreferences.remove(_tokenKey);
    await sharedPreferences.remove(_externalPosIdKey);
  }
}
