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

  factory Company.fromFirestore(Map<String, dynamic> data,) {
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
}

class FirestoreUserDataSourceImpl implements FirestoreUserDataSource {
  final FirebaseFirestore _firestore;

  FirestoreUserDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  // validar primero campo enabled y ahi si es true traer el resto de los datos, sino no traer nada
  Future<List<Company>> getCompaniesByEmail(String email) async {
    try {
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
}
