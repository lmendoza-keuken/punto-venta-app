import 'package:punto_venta_app/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> loginWithGoogle();
  Future<Map<String, dynamic>> selectCompany(String email, int companyId);
  Future<User> authenticateUser(String email, int companyId, String username, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<bool> isLoggedIn();
}