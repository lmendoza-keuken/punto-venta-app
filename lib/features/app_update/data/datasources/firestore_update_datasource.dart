import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/app_update/data/models/app_release_model.dart';
import 'package:punto_venta_app/firebase_options.dart';

abstract class FirestoreUpdateDatasource {
  Future<AppReleaseModel?> fetchWindowsRelease();
}

class FirestoreUpdateDatasourceImpl implements FirestoreUpdateDatasource {
  static const String collectionName = 'appVersionsInfo';
  static const String documentId = 'punto_venta';
  static const Duration _timeout = Duration(seconds: 8);

  final FirebaseFirestore _firestore;

  FirestoreUpdateDatasourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  Future<AppReleaseModel?> fetchWindowsRelease() async {
    if (_isWindows) {
      return _fetchViaRest();
    }

    try {
      final doc = await _firestore
          .collection(collectionName)
          .doc(documentId)
          .get()
          .timeout(_timeout);

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return AppReleaseModel.fromMap(doc.data()!);
    } catch (e, stackTrace) {
      AppLogger.error(
        'AppUpdate: native Firestore failed, trying REST',
        e,
        stackTrace,
      );
      return _fetchViaRest();
    }
  }

  Future<AppReleaseModel?> _fetchViaRest() async {
    try {
      final token = await _getAuthToken();
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
      final uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId'
        '/databases/(default)/documents/$collectionName/$documentId',
      );

      final response =
          await http.get(uri, headers: headers).timeout(_timeout);
      AppLogger.info(
        'AppUpdate: Firestore REST status=${response.statusCode}',
      );

      if (response.statusCode == 404) {
        return null;
      }
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final jsonBody = json.decode(response.body) as Map<String, dynamic>;
      final fields = _parseFirestoreRestFields(
        jsonBody['fields'] as Map<String, dynamic>?,
      );
      if (fields.isEmpty) return null;
      return AppReleaseModel.fromMap(fields);
    } catch (e, stackTrace) {
      AppLogger.error('AppUpdate: Firestore REST failed', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene un token anónimo REST de Firebase Auth para llamadas REST a Firestore.
  Future<String?> _getAuthToken() async {
    try {
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final response = await http
          .post(
            Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'returnSecureToken': true}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['idToken'] as String?;
      } else {
        AppLogger.warn(
          'AppUpdate: Firebase Auth REST signup status=${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'AppUpdate: error al obtener REST ID Token de Firebase',
        e,
        stackTrace,
      );
    }
    return null;
  }

  Map<String, dynamic> _parseFirestoreRestFields(Map<String, dynamic>? fields) {
    if (fields == null) return {};
    final result = <String, dynamic>{};
    fields.forEach((key, valMap) {
      if (valMap is Map<String, dynamic>) {
        if (valMap.containsKey('stringValue')) {
          result[key] = valMap['stringValue'];
        } else if (valMap.containsKey('integerValue')) {
          result[key] =
              int.tryParse(valMap['integerValue'].toString()) ?? 0;
        } else if (valMap.containsKey('doubleValue')) {
          result[key] =
              double.tryParse(valMap['doubleValue'].toString()) ?? 0.0;
        } else if (valMap.containsKey('booleanValue')) {
          result[key] = valMap['booleanValue'];
        } else if (valMap.containsKey('nullValue')) {
          result[key] = null;
        } else if (valMap.containsKey('timestampValue')) {
          result[key] = valMap['timestampValue'];
        } else if (valMap.containsKey('mapValue')) {
          final subMap = (valMap['mapValue'] as Map<String, dynamic>)['fields']
              as Map<String, dynamic>?;
          result[key] = _parseFirestoreRestFields(subMap);
        }
      }
    });
    return result;
  }
}
