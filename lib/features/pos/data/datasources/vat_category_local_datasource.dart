import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vat_category_model.dart';

abstract class VatCategoryLocalDataSource {
  Future<List<VatCategoryModel>?> getCachedVatCategories();
  Future<void> cacheVatCategories(List<VatCategoryModel> vatCategories);
  Future<void> clearCache();
}

class VatCategoryLocalDataSourceImpl implements VatCategoryLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _vatCategoriesKey = 'CACHED_VAT_CATEGORIES';

  VatCategoryLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<VatCategoryModel>?> getCachedVatCategories() async {
    final jsonString = sharedPreferences.getString(_vatCategoriesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
      return list
          .map((e) => VatCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheVatCategories(List<VatCategoryModel> vatCategories) async {
    final jsonString = json.encode(vatCategories.map((v) => v.toJson()).toList());
    await sharedPreferences.setString(_vatCategoriesKey, jsonString);
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(_vatCategoriesKey);
  }
}
