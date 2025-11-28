import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:punto_venta_app/features/auth/data/datasources/firestore_user_datasource.dart';
import 'package:punto_venta_app/features/auth/data/datasources/user_api_datasource.dart';
import 'package:punto_venta_app/features/auth/data/models/enterprise_model.dart';
import 'package:punto_venta_app/features/auth/data/models/user_model.dart';
import 'package:punto_venta_app/features/auth/domain/entities/enterprise.dart';
import 'package:punto_venta_app/features/auth/domain/entities/user.dart';
import 'package:punto_venta_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final GoogleAuthDataSource googleAuthDataSource;
  final FirestoreUserDataSource firestoreUserDataSource;
  final UserApiDataSource userApiDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.googleAuthDataSource,
    required this.firestoreUserDataSource,
    required this.userApiDataSource,
  });

  @override
  Future<Map<String, dynamic>> loginWithGoogle() async {
    final googleEmail = await googleAuthDataSource.signInWithGoogle();

    if (googleEmail == null) {
      throw Exception('Inicio de sesión cancelado');
    }

    if (googleEmail.isEmpty) {
      throw Exception('No se pudo obtener el email del usuario');
    }

    try {
      final companies =
          await firestoreUserDataSource.getCompaniesByEmail(googleEmail);

      if (companies.isEmpty) {
        await googleAuthDataSource.signOut();
        throw Exception(
            'No hay empresas vinculadas a este correo. Por favor contacta al administrador.');
      }

      return {
        'email': googleEmail,
        'companies': companies.map((c) => c.toMap()).toList(),
        'autoSelected': companies.length == 1,
      };
    } catch (e) {
      await googleAuthDataSource.signOut();
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> selectCompany(
      String email, int companyId) async {
    final companies = await firestoreUserDataSource.getCompaniesByEmail(email);

    final selectedCompany = companies.firstWhere(
      (c) => c.id.toString() == companyId.toString(),
      orElse: () => throw Exception('Empresa no encontrada'),
    );

    // para debug
    ApiConfig.updateCompanyId("99999999");

    // ApiConfig.updateCompanyId(companyId.toString());

    final enterpriseModel = EnterpriseModel(
      id: selectedCompany.id,
      name: selectedCompany.name,
    );
    await localDataSource.cacheEnterprise(enterpriseModel);

    return {
      'email': email,
      'companyId': companyId,
      'companyName': selectedCompany.name,
    };
  }

  @override
  Future<User> authenticateUser(
    String email,
    int companyId,
    String userId,
    String password,
  ) async {
    try {
      final userData =
          await userApiDataSource.authenticateUser(userId, password);

      final user = User(
        id: userData['id']?.toString() ?? userId,
        name: userData['name']?.toString() ?? '',
        tipo: userData['tipo']?.toString() ?? '',
        idsup: userData['idsup']?.toString() ?? '',
        supervisor: userData['supervisor']?.toString() ?? '',
        email: email,
        photoUrl: userData['photoUrl']?.toString(),
        companyIds: [companyId],
      );

      final userModel = UserModel.fromEntity(user);

      // Guardar en caché local
      await localDataSource.cacheUser(userModel);

      return user;
    } catch (e) {
      throw Exception('Error al autenticar usuario: $e');
    }
  }

  @override
  Future<void> logout() async {
    await googleAuthDataSource.signOut();
    await localDataSource.logout();
    await localDataSource.clearEnterprise();
    // Reset any necessary configurations (ApiConfig)
     
    ApiConfig.updateCompanyId("99999999"); // Reset a default
  }

  @override
  Future<void> changeCashier() async {
    await localDataSource.logout();

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
