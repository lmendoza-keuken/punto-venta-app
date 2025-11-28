import 'dart:convert';
import 'package:punto_venta_app/features/auth/data/models/enterprise_model.dart';
import 'package:punto_venta_app/features/auth/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> logout();
  Future<UserModel?> getCachedUser();
  Future<EnterpriseModel?> getCachedEnterprise();
  Future<void> cacheUser(UserModel user);
  Future<void> cacheEnterprise(EnterpriseModel enterprise);
  Future<void> clearEnterprise();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String cachedUserKey = 'CACHED_USER';
  static const String cachedEnterpriseKey = 'CACHED_ENTERPRISE';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  
  @override
  Future<void> logout() async {
    await sharedPreferences.remove(cachedUserKey);
  }

   @override
  Future<void> clearEnterprise() async {
    await sharedPreferences.remove(cachedEnterpriseKey);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = sharedPreferences.getString(cachedUserKey);
    if (jsonString != null) {
      return UserModel.fromJson(json.decode(jsonString));
    }
    return null;
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await sharedPreferences.setString(
      cachedUserKey,
      json.encode(user.toJson()),
    );
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
}

