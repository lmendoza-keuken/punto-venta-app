import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tax_model.dart';

abstract class TaxLocalDataSource {
  Future<List<TaxModel>?> getCachedTaxes();
  Future<void> cacheTaxes(List<TaxModel> taxes);
  Future<void> clearCache();
}

class TaxLocalDataSourceImpl implements TaxLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _taxesKey = 'CACHED_TAXES';

  TaxLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<TaxModel>?> getCachedTaxes() async {
    final jsonString = sharedPreferences.getString(_taxesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
      return list
          .map((e) => TaxModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheTaxes(List<TaxModel> taxes) async {
    final jsonString = json.encode(taxes.map((t) => t.toJson()).toList());
    await sharedPreferences.setString(_taxesKey, jsonString);
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(_taxesKey);
  }
}
