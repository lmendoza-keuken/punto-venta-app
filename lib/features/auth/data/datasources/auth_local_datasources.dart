import 'dart:convert';
import 'package:punto_venta_app/features/auth/data/models/enterprise_model.dart';
import 'package:punto_venta_app/features/auth/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> logout(); 
  Future<EnterpriseModel?> getCachedEnterprise();
  Future<void> cacheEnterprise(EnterpriseModel enterprise);
  Future<void> cacheEmail(String email);
  Future<String?> getCachedEmail();
  Future<void> clearEnterprise();
  Future<void> clearEmail();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  UserModel? _volatileUser;

  static const String cachedEnterpriseKey = 'CACHED_ENTERPRISE';
  static const String cachedEmailKey = 'CACHED_EMAIL';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserModel?> getCachedUser() async {
    return _volatileUser;
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    _volatileUser = user;
  }

  @override
  Future<void> logout() async {
    _volatileUser = null;
  }

  @override
  Future<EnterpriseModel?> getCachedEnterprise() async {
    final jsonString = sharedPreferences.getString(cachedEnterpriseKey);
    if (jsonString != null) {
      return EnterpriseModel.fromJson(json.decode(jsonString));
    }
    return null;
  }

  @override
  Future<void> cacheEnterprise(EnterpriseModel enterprise) async {
    await sharedPreferences.setString(
      cachedEnterpriseKey,
      json.encode(enterprise.toJson()),
    );
  }

  @override
  Future<void> cacheEmail(String email) async {
    await sharedPreferences.setString(cachedEmailKey, email);
  }

  @override
  Future<String?> getCachedEmail() async {
    return sharedPreferences.getString(cachedEmailKey);
  }

  @override
  Future<void> clearEnterprise() async {
    await sharedPreferences.remove(cachedEnterpriseKey);
  }

  @override
  Future<void> clearEmail() async {
    await sharedPreferences.remove(cachedEmailKey);
  }
}
