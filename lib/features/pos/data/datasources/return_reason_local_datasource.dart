import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:punto_venta_app/features/pos/data/models/return_reason_model.dart';

abstract class ReturnReasonLocalDataSource {
  Future<List<ReturnReasonModel>?> getCachedReturnReasons();
  Future<void> cacheReturnReasons(List<ReturnReasonModel> reasons);
}

class ReturnReasonLocalDataSourceImpl implements ReturnReasonLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _key = 'CACHED_RETURN_REASONS';

  ReturnReasonLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<ReturnReasonModel>?> getCachedReturnReasons() async {
    final jsonString = sharedPreferences.getString(_key);
    if (jsonString == null) return null;

    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    return jsonList
        .map((e) => ReturnReasonModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheReturnReasons(List<ReturnReasonModel> reasons) async {
    final jsonString = json.encode(reasons.map((r) => r.toJson()).toList());
    await sharedPreferences.setString(_key, jsonString);
  }
}
