import 'dart:convert';
import 'package:punto_venta_app/features/pos/data/models/price_list_type_response_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PriceListTypesLocalDataSource {
  Future<List<PriceListTypeResponseModel>?> getCachedPriceListTypes();
  Future<void> cachePriceListTypes(List<PriceListTypeResponseModel> priceListTypes);
  Future<PriceListTypeResponseModel?> getPriceListTypeById(int priceListTypeId);
}

class PriceListTypesLocalDataSourceImpl implements PriceListTypesLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _key = 'CACHED_PRICE_LIST_TYPES';

  PriceListTypesLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<PriceListTypeResponseModel>?> getCachedPriceListTypes() async {
    final jsonString = sharedPreferences.getString(_key);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((e) => PriceListTypeResponseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  @override
  Future<void> cachePriceListTypes(List<PriceListTypeResponseModel> priceListTypes) async {
    final jsonString =
        json.encode(priceListTypes.map((p) => p.toJson()).toList());
    await sharedPreferences.setString(_key, jsonString);
  }

  @override
  Future<PriceListTypeResponseModel?> getPriceListTypeById(int priceListTypeId) async {
    final priceListTypes = await getCachedPriceListTypes();
    if (priceListTypes == null) return null;

    try {
      return priceListTypes.firstWhere((p) => p.id == priceListTypeId);
    } catch (e) {
      return null;
    }
  }
}
