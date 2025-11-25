import 'package:punto_venta_app/features/auth/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

abstract class AuthLocalDataSource {
  Future<UserModel> login(String username, String password);
  Future<void> logout();
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String cachedUserKey = 'CACHED_USER';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserModel> login(String username, String password) async {
    // Simulación de login - en producción conectarías con API
    await Future.delayed(const Duration(seconds: 1));

    // Credenciales de demo
    if (username == 'admin' && password == 'admin') {
      const user = UserModel(
        id: '1',
        username: 'admin',
        name: 'Administrador',
        role: 'admin',
      );
      await cacheUser(user);
      return user;
    } else if (username == 'user' && password == '1234') {
      const user = UserModel(
        id: '2',
        username: 'user',
        name: 'Usuario Demo',
        role: 'user',
      );
      await cacheUser(user);
      return user;
    } else {
      throw Exception('Credenciales inválidas');
    }
  }

  @override
  Future<void> logout() async {
    await sharedPreferences.remove(cachedUserKey);
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
}
