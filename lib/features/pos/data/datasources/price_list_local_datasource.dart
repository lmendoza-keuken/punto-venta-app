import 'package:shared_preferences/shared_preferences.dart';

abstract class PriceListLocalDataSource {
  Future<int> getCurrentPriceList();
  Future<void> savePriceList(int listId);
  Future<void> clearPriceList();
}

class PriceListLocalDataSourceImpl implements PriceListLocalDataSource {
  static const String _priceListKey = 'CURRENT_PRICE_LIST';
  final SharedPreferences sharedPreferences;
  PriceListLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<int> getCurrentPriceList() async {
    return sharedPreferences.getInt(_priceListKey)!;
  }

  @override
  Future<void> savePriceList(int listId) async {
    await sharedPreferences.setInt(_priceListKey, listId);
  }

  @override
  Future<void> clearPriceList() async {
    await sharedPreferences.remove(_priceListKey);
  }
}