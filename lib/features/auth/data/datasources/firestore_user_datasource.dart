import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final int id;
  final String name;
  final String? baseUrl;
  final int? listPriceId;

  Company({
    required this.id,
    required this.name,
    this.baseUrl,
    this.listPriceId,
  });

  factory Company.fromFirestore(
    Map<String, dynamic> data,
  ) {
    return Company(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      baseUrl: data['baseUrl']?.toString(),
      listPriceId: data['listPriceId'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'listPriceId': listPriceId,
    };
  }
}

abstract class FirestoreUserDataSource {
  Future<List<Company>> getCompaniesByEmail(String email);
  Future<String?> getPdvBaseUrl(int enterpriseId);
}

class FirestoreUserDataSourceImpl implements FirestoreUserDataSource {
  final FirebaseFirestore _firestore;

  FirestoreUserDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Company>> getCompaniesByEmail(String email) async {
    try {
      // validar si el usuario está habilitado
      final userDoc =
          await _firestore.collection('usersEmail').doc(email).get();

      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data();
      final isEnabled = userData?['enabled'] ?? false;

      if (!isEnabled) {
        throw Exception(
            'Usuario no habilitado. Por favor contacta al administrador.');
      }

      // Si está habilitado, obtener las empresas
      final enterprisesSnapshot = await _firestore
          .collection('usersEmail')
          .doc(email)
          .collection('enterprises')
          .get();

      if (enterprisesSnapshot.docs.isEmpty) {
        return [];
      }

      return enterprisesSnapshot.docs.map((doc) {
        return Company.fromFirestore(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener empresas desde Firestore: $e');
    }
  }

  @override
  Future<String?> getPdvBaseUrl(int enterpriseId) async {
    try {
      final licenseDoc = await _firestore
          .collection('enterprisesLicense')
          .doc(enterpriseId.toString())
          .get();

      if (!licenseDoc.exists) {
        return null;
      }

      final data = licenseDoc.data();
      return data?['pointOfSaleUrl']?.toString();
    } catch (e) {
      throw Exception('Error al obtener PdvBaseUrl desde Firestore: $e');
    }
  }
}
