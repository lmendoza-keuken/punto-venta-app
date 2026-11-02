import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:punto_venta_app/features/pos/data/models/product_image_model.dart';

class ProductImagesRepository {
  final FirebaseStorage _storage;
  final Map<String, String> _imageCache = {};
  Future<Map<String, String>>? _inFlightFetch;

  /// TEMP: mock local de imagen para producto código 3 (solo debug).
  static const String _tempMockProduct3Asset =
      'asset:assets/mock/product_3_secco_naranja.jpg';

  ProductImagesRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<Map<String, String>> fetchProductImages(String enterpriseId) async {
    if (_imageCache.isNotEmpty) {
      _applyTempMocks();
      return _imageCache;
    }
    if (_inFlightFetch != null) {
      return _inFlightFetch!;
    }

    _inFlightFetch = _downloadAndCache(enterpriseId);
    try {
      await _inFlightFetch!;
      _applyTempMocks();
      return _imageCache;
    } finally {
      _inFlightFetch = null;
    }
  }

  void _applyTempMocks() {
    if (!kDebugMode) return;
    // TODO(temp): quitar cuando ProductLinks.json tenga la foto real.
    _imageCache['3'] = _tempMockProduct3Asset;
  }

  /// Precarga en background; no bloquea el flujo de login.
  void prefetchProductImages(String enterpriseId) {
    if (_imageCache.isNotEmpty || _inFlightFetch != null) return;
    fetchProductImages(enterpriseId);
  }

  Future<Map<String, String>> _downloadAndCache(String enterpriseId) async {
    try {
      final ref =
          _storage.ref().child('$enterpriseId/data/photo/ProductLinks.json');

      final data = await ref.getData();
      if (data == null) {
        throw Exception('No se pudo cargar el archivo de imágenes');
      }

      final jsonString = utf8.decode(data);
      final List<dynamic> jsonList = json.decode(jsonString);

      final List<ProductImageModel> images = jsonList
          .map((json) =>
              ProductImageModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final Map<String, List<ProductImageModel>> groupedImages = {};
      for (final image in images) {
        final code = image.codigo ?? '';
        groupedImages.putIfAbsent(code, () => []).add(image);
      }

      for (final entry in groupedImages.entries) {
        final backupImage = entry.value.firstWhere(
          (img) => img.backup ?? false,
          orElse: () => entry.value.first,
        );
        _imageCache[entry.key] = backupImage.link ?? '';
      }

      return _imageCache;
    } catch (_) {
      return {};
    }
  }

  String? getImageUrl(String productCode) {
    return _imageCache[productCode];
  }

  void clearCache() {
    _imageCache.clear();
    _inFlightFetch = null;
  }
}
