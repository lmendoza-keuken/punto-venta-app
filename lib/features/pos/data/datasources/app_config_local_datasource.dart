import 'package:sqflite/sqflite.dart';
import 'package:punto_venta_app/core/database/database_helper.dart';
import 'package:punto_venta_app/features/pos/data/models/app_config_model.dart';

abstract class AppConfigLocalDataSource {
  Future<AppConfigModel?> getAppConfig();
  Future<void> saveAppConfig(AppConfigModel config);
  Future<void> deleteAppConfig();
}

class AppConfigLocalDataSourceImpl implements AppConfigLocalDataSource {
  final DatabaseHelper dbHelper;
  static const String _tableName = 'pdv_config';

  AppConfigLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<AppConfigModel?> getAppConfig() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        _tableName,
        limit: 1,
        orderBy: 'lastUpdated DESC',
      );

      if (results.isEmpty) {
        return null;
      }

      return AppConfigModel.fromMap(results.first);
    } catch (e) {
      throw Exception('Error al obtener configuración de tickets: $e');
    }
  }

  @override
  Future<void> saveAppConfig(AppConfigModel config) async {
    try {
      final db = await dbHelper.database;

      await db.delete(_tableName);

      await db.insert(
        _tableName,
        config.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Error al guardar configuración de tickets: $e');
    }
  }

  @override
  Future<void> deleteAppConfig() async {
    try {
      final db = await dbHelper.database;
      await db.delete(_tableName);
    } catch (e) {
      throw Exception('Error al eliminar configuración de tickets: $e');
    }
  }
}
