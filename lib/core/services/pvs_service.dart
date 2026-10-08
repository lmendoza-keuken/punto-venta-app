import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:punto_venta_app/features/pos/data/models/pvs/pvs_qr_generate_request_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pvs/pvs_qr_generate_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pvs/pvs_reverse_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pvs/pvs_token_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pvs/pvs_transaction_status_response_model.dart';

class PvsService {
  final String baseUrl = 'https://api01.pvssa.com.ar';
  late Dio _dio;

  PvsService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Future<PvsTokenResponse> getAccessToken({
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      final basic =
          base64Encode(utf8.encode('$clientId:$clientSecret'));
      final response = await _dio.post(
        '/oauth2/token',
        data: 'grant_type=client_credentials',
        options: Options(
          headers: {
            'Authorization': 'Basic $basic',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );
      return PvsTokenResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        'Error obteniendo token PVS: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<PvsQrGenerateResponse> generateQr({
    required String accessToken,
    required PvsQrGenerateRequest request,
  }) async {
    try {
      final response = await _dio.post(
        '/external/connect/api/v1/qr/pvs',
        data: request.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      return PvsQrGenerateResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        'Error generando QR PVS: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<PvsTransactionStatusResponse> checkQrStatus({
    required String accessToken,
    required String qrId,
  }) async {
    try {
      final response = await _dio.get(
        '/external/connect/api/v1/transactions/qrpvs/$qrId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      return PvsTransactionStatusResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        'Error consultando estado PVS: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<PvsReverseResponse> reverseQr({
    required String accessToken,
    required String qrId,
  }) async {
    try {
      final response = await _dio.post(
        '/external/connect/api/v1/qr/pvs/reverse',
        data: {'qrId': qrId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      final data = response.data;
      if (data is Map) {
        return PvsReverseResponse.fromJson(Map<String, dynamic>.from(data));
      }
      return PvsReverseResponse(qrId: qrId);
    } on DioException catch (e) {
      throw Exception(
        'Error revirtiendo QR PVS: ${e.response?.data ?? e.message}',
      );
    }
  }
}
