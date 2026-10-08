import 'package:dio/dio.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/mercado_pago_qr_request_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/mercado_pago_qr_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/order_refund_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/pos_request_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/pos_response_model.dart';
import 'package:uuid/uuid.dart';

class MercadoPagoService {
  String? _accessToken;
  final String baseUrl = 'https://api.mercadopago.com';
  late Dio _dio;

  MercadoPagoService() {
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

  void setAccessToken(String token) {
    _accessToken = token;
    _initializeDio();
  }

  String? get accessToken => _accessToken;

  Future<MercadoPagoQrResponse> generateQrOrder({
    required MercadoPagoQrRequest qrRequest,
  }) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('Token de MercadoPago no configurado');
    }

    try {
      final response = await _dio.post(
        '/v1/orders',
        data: qrRequest.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'X-Idempotency-Key': const Uuid().v4(),
          },
        ),
      );

      return MercadoPagoQrResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error generando QR: ${e.response?.data ?? e.message}');
    }
  }

  Future<MercadoPagoQrResponse> checkQrOrderStatus({
    required String orderId,
  }) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('Token de MercadoPago no configurado');
    }

    try {
      final response = await _dio.get(
        '/v1/orders/$orderId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      return MercadoPagoQrResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          'Error consultando estado: ${e.response?.data ?? e.message}');
    }
  }

  Future<MercadoPagoQrResponse> cancelQrOrder({
    required String orderId,
  }) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('Token de MercadoPago no configurado');
    }

    try {
      final response = await _dio.post(
        '/v1/orders/$orderId/cancel',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'X-Idempotency-Key': const Uuid().v4(),
          },
        ),
      );

      return MercadoPagoQrResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error cancelando QR: ${e.response?.data ?? e.message}');
    }
  }

  Future<OrderRefundResponse> refundQrOrder({
    required String orderId,
  }) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('Token de MercadoPago no configurado');
    }

    try {
      final response = await _dio.post(
        '/v1/orders/$orderId/refund',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'X-Idempotency-Key': const Uuid().v4(),
          },
        ),
      );

      return OrderRefundResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          'Error reembolsando QR: ${e.response?.data ?? e.message}');
    }
  }

  Future<PosResponseModel> createPos({
    required PosRequestModel posRequest,
  }) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('Token de MercadoPago no configurado');
    }

    try {
      final response = await _dio.post(
        '/pos',
        data: posRequest.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      return PosResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error creando POS: ${e.response?.data ?? e.message}');
    }
  }
}
