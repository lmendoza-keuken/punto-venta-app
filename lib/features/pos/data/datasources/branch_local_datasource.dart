import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/branch_response_model.dart';

abstract class BranchLocalDataSource {
  Future<List<BranchResponseModel>?> getCachedBranches();
  Future<void> cacheBranches(List<BranchResponseModel> branches);
  Future<BranchResponseModel?> getBranchById(int branchId);
}

class BranchLocalDataSourceImpl implements BranchLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _key = 'CACHED_BRANCHES';

  BranchLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<BranchResponseModel>?> getCachedBranches() async {
    final jsonString = sharedPreferences.getString(_key);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((e) => BranchResponseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  @override
  Future<void> cacheBranches(List<BranchResponseModel> branches) async {
    final jsonString =
        json.encode(branches.map((b) => b.toJson()).toList());
    await sharedPreferences.setString(_key, jsonString);
  }

  @override
  Future<BranchResponseModel?> getBranchById(int branchId) async {
    final branches = await getCachedBranches();
    if (branches == null) return null;
    
    try {
      return branches.firstWhere((b) => b.branchId == branchId);
    } catch (e) {
      return null;
    }
  }
}
