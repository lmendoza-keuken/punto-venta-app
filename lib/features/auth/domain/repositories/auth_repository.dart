import 'package:punto_venta_app/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> loginWithGoogle();
  Future<Map<String, dynamic>> selectCompany(String email, int companyId);
  Future<User> authenticateUser(String username, String password);
  Future<void> changeCashier();
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<bool> isLoggedIn();
}
