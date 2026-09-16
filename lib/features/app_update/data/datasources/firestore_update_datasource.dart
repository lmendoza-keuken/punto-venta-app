import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/app_update/data/models/app_release_model.dart';
import 'package:punto_venta_app/features/app_update/domain/utils/app_update_error.dart';
import 'package:punto_venta_app/firebase_options.dart';

abstract class FirestoreUpdateDatasource {
  Future<AppReleaseModel?> fetchWindowsRelease();
}

class FirestoreUpdateDatasourceImpl implements FirestoreUpdateDatasource {
  static const String collectionName = 'appVersionsInfo';
  static const String documentId = 'punto_venta';
  static const Duration _timeout = Duration(seconds: 20);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreUpdateDatasourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  Future<AppReleaseModel?> fetchWindowsRelease() async {
    final totalSw = Stopwatch()..start();
    AppLogger.info(
      'AppUpdate: fetching $collectionName/$documentId isWindows=$_isWindows '
      'timeoutMs=${_timeout.inMilliseconds}',
    );
    try {
      if (_isWindows) {
        final model = await _fetchViaRest();
        AppLogger.info(
          'AppUpdate: fetch done via=REST ok=${model != null} '
          'elapsedMs=${totalSw.elapsedMilliseconds}',
        );
        return model;
      }

      try {
        final nativeSw = Stopwatch()..start();
        AppLogger.info('AppUpdate: stage=nativeGet start');
        final doc = await _firestore
            .collection(collectionName)
            .doc(documentId)
            .get()
            .timeout(_timeout);
        AppLogger.info(
          'AppUpdate: stage=nativeGet done elapsedMs=${nativeSw.elapsedMilliseconds} '
          'exists=${doc.exists}',
        );

        if (!doc.exists || doc.data() == null) {
          AppLogger.warn('AppUpdate: document missing (native)');
          return null;
        }

        final model = AppReleaseModel.fromMap(doc.data()!);
        AppLogger.info(
          'AppUpdate: native doc version=${model.version} '
          'buildNumber=${model.buildNumber} '
          'minSupported=${model.minSupportedBuildVersion}',
        );
        return model;
    } catch (e, stackTrace) {
      logAppUpdateFailure(
        'nativeGet',
        e,
        stackTrace,
      );
      AppLogger.info('AppUpdate: falling back to REST after native failure');
      return _fetchViaRest();
    }
    } catch (e, stackTrace) {
      logAppUpdateFailure(
        'fetchWindowsRelease',
        e,
        stackTrace,
        elapsedMs: totalSw.elapsedMilliseconds,
      );
      rethrow;
    }
  }

  Future<AppReleaseModel?> _fetchViaRest() async {
    final restSw = Stopwatch()..start();
    try {
      AppLogger.info('AppUpdate: stage=authToken start');
      final tokenSw = Stopwatch()..start();
      final token = await _getAuthToken();
      AppLogger.info(
        'AppUpdate: stage=authToken done elapsedMs=${tokenSw.elapsedMilliseconds} '
        'hasToken=${token != null && token.isNotEmpty} '
        'tokenLen=${token?.length ?? 0}',
      );

      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        AppLogger.warn(
          'AppUpdate: sin token auth; Firestore puede devolver 403',
        );
      }

      final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
      final uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId'
        '/databases/(default)/documents/$collectionName/$documentId',
      );

      AppLogger.info(
        'AppUpdate: stage=httpGet start host=${uri.host} '
        'path=${uri.path} timeoutMs=${_timeout.inMilliseconds}',
      );
      final httpSw = Stopwatch()..start();
      final response =
          await http.get(uri, headers: headers).timeout(_timeout);
      AppLogger.info(
        'AppUpdate: stage=httpGet done elapsedMs=${httpSw.elapsedMilliseconds} '
        'status=${response.statusCode} bodyLen=${response.body.length}',
      );

      if (response.statusCode == 404) {
        AppLogger.warn(
          'AppUpdate: 404 en $collectionName/$documentId '
          '(¿el doc existe en este proyecto?)',
        );
        return null;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        AppLogger.warn(
          'AppUpdate: auth/permiso HTTP ${response.statusCode} '
          'body=${_truncate(response.body)}',
        );
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
      if (response.statusCode != 200) {
        AppLogger.warn(
          'AppUpdate: HTTP ${response.statusCode} body=${_truncate(response.body)}',
        );
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      AppLogger.info('AppUpdate: stage=parse start');
      final parseSw = Stopwatch()..start();
      final jsonBody = json.decode(response.body) as Map<String, dynamic>;
      final fields = _parseFirestoreRestFields(
        jsonBody['fields'] as Map<String, dynamic>?,
      );
      AppLogger.info(
        'AppUpdate: stage=parse done elapsedMs=${parseSw.elapsedMilliseconds} '
        'keys=${fields.keys.toList()}',
      );
      if (fields.isEmpty) {
        AppLogger.warn('AppUpdate: REST fields vacíos');
        return null;
      }

      final model = AppReleaseModel.fromMap(fields);
      AppLogger.info(
        'AppUpdate: REST doc version=${model.version} '
        'buildNumber=${model.buildNumber} '
        'minSupported=${model.minSupportedBuildVersion} '
        'mandatory=${model.mandatory} '
        'downloadUrlEmpty=${model.downloadUrl.isEmpty} '
        'restTotalMs=${restSw.elapsedMilliseconds}',
      );
      return model;
    } catch (e, stackTrace) {
      logAppUpdateFailure(
        'httpGetOrParse',
        e,
        stackTrace,
        elapsedMs: restSw.elapsedMilliseconds,
      );
      rethrow;
    }
  }

  /// Prefer the anonymous session from [main], then REST signUp like auth datasource.
  Future<String?> _getAuthToken() async {
    try {
      final user = _auth.currentUser;
      AppLogger.info(
        'AppUpdate: auth currentUserNull=${user == null} '
        'uid=${user?.uid}',
      );
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null && token.isNotEmpty) {
          AppLogger.info('AppUpdate: using FirebaseAuth.currentUser token');
          return token;
        }
        AppLogger.warn('AppUpdate: currentUser token vacío');
      }
    } catch (e, stackTrace) {
      logAppUpdateFailure('currentUser.getIdToken', e, stackTrace);
      AppLogger.info('AppUpdate: trying REST signup after currentUser token fail');
    }

    try {
      AppLogger.info('AppUpdate: stage=restSignUp start');
      final signUpSw = Stopwatch()..start();
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

      AppLogger.info(
        'AppUpdate: stage=restSignUp done elapsedMs=${signUpSw.elapsedMilliseconds} '
        'status=${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        AppLogger.info('AppUpdate: using REST anonymous signup token');
        return data['idToken'] as String?;
      } else {
        AppLogger.warn(
          'AppUpdate: Firebase Auth REST signup status=${response.statusCode} '
          'body=${_truncate(response.body)}',
        );
      }
    } catch (e, stackTrace) {
      logAppUpdateFailure('restSignUp', e, stackTrace);
    }
    return null;
  }

  static String _truncate(String value, [int max = 300]) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}…';
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
