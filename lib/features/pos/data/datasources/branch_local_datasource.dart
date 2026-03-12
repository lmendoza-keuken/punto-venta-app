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
    print('[BRANCH_DS] 🔍 Buscando branch_id=$branchId');
    print('[BRANCH_DS] 📋 Branches en caché: ${branches?.length ?? 0}');
    
    if (branches == null) {
      print('[BRANCH_DS] ❌ No hay branches en caché');
      return null;
    }
    
    print('[BRANCH_DS] IDs disponibles: ${branches.map((b) => b.branchId).join(', ')}');
    
    try {
      final found = branches.firstWhere((b) => b.branchId == branchId);
      print('[BRANCH_DS] ✅ Branch encontrada: ${found.name} (id: ${found.branchId})');
      return found;
    } catch (e) {
      print('[BRANCH_DS] ❌ Branch no encontrada con id=$branchId');
      return null;
    }
  }
}
