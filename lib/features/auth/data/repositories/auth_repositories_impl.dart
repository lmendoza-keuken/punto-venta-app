import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/auth/domain/entities/user.dart';
import 'package:punto_venta_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<User> login(String username, String password) async {
    final userModel = await localDataSource.login(username, password);
    return userModel.toEntity();
  }

  @override
  Future<void> logout() async {
    return await localDataSource.logout();
  }

  @override
  Future<User?> getCurrentUser() async {
    final userModel = await localDataSource.getCachedUser();
    return userModel?.toEntity();
  }

  @override
  Future<bool> isLoggedIn() async {
    final user = await localDataSource.getCachedUser();
    return user != null;
  }
}
