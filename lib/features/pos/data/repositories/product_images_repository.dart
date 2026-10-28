import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:punto_venta_app/features/pos/data/models/product_image_model.dart';

class ProductImagesRepository {
  final FirebaseStorage _storage;
  final Map<String, String> _imageCache = {};
  Future<Map<String, String>>? _inFlightFetch;

  ProductImagesRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<Map<String, String>> fetchProductImages(String enterpriseId) async {
    if (_imageCache.isNotEmpty) {
      return _imageCache;
    }
    if (_inFlightFetch != null) {
      return _inFlightFetch!;
    }

    _inFlightFetch = _downloadAndCache(enterpriseId);
    try {
      return await _inFlightFetch!;
    } finally {
      _inFlightFetch = null;
    }
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
