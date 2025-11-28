import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:punto_venta_app/core/config/api_config.dart';

abstract class UserApiDataSource {
  Future<Map<String, dynamic>> authenticateUser(String userId, String password);
}

class UserApiDataSourceImpl implements UserApiDataSource {
  List<Map<String, dynamic>>? _cachedUsers;

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    if (_cachedUsers != null) {
      return _cachedUsers!;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.usersUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, GET, OPTIONS, PUT, DELETE, HEAD",
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData;
        try {
          final String responseBody = utf8.decode(response.bodyBytes);
          jsonData = json.decode(responseBody);
        } catch (e) {
          final String responseBody = latin1.decode(response.bodyBytes);
          jsonData = json.decode(responseBody);
        }

        _cachedUsers = jsonData
            .map((json) => json as Map<String, dynamic>)
            .toList();

        return _cachedUsers!;
      } else {
        throw Exception('Error al cargar usuarios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> authenticateUser(String userId, String password) async {
    final users = await _fetchUsers();

    try {
      final user = users.firstWhere(
        (user) =>
            user['id']?.toString() == userId &&
            user['password']?.toString() == password,
      );

      return user;
    } catch (e) {
      throw Exception('ID de usuario o contraseña incorrectos');
    }
  }

  void clearCache() {
    _cachedUsers = null;
  }
}