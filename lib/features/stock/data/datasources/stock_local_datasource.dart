import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:punto_venta_app/core/database/database_helper.dart';
import 'package:punto_venta_app/features/stock/data/models/stock_movement_model.dart';

abstract class StockLocalDatasource {
  Future<int> getProductStock(int codigo);
  Future<void> updateProductStock(int codigo, int newStock);
  Future<void> initializeProductStock(int codigo, int initialStock);
  Future<StockMovementModel> createMovement(StockMovementModel movement);
  Future<List<StockMovementModel>> getProductMovements(int codigo);
  Future<List<StockMovementModel>> getAllMovements({DateTime? fromDate, DateTime? toDate});
}

class StockLocalDatasourceImpl implements StockLocalDatasource {
  final DatabaseHelper databaseHelper;
  final Uuid uuid;

  StockLocalDatasourceImpl({
    required this.databaseHelper,
    required this.uuid,
  });

  @override
  Future<int> getProductStock(int codigo) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      'product_stock',
      where: 'codigo = ?',
      whereArgs: [codigo],
      limit: 1,
    );

    if (maps.isEmpty) {
      // Si no existe, inicializar con stock 0
      await initializeProductStock(codigo, 0);
      return 0;
    }

    return maps.first['stock'] as int;
  }

  @override
  Future<void> initializeProductStock(int codigo, int initialStock) async {
    final db = await databaseHelper.database;
    await db.insert(
      'product_stock',
      {
        'codigo': codigo,
        'stock': initialStock,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateProductStock(int codigo, int newStock) async {
    final db = await databaseHelper.database;
    
    final existing = await db.query(
      'product_stock',
      where: 'codigo = ?',
      whereArgs: [codigo],
    );

    if (existing.isEmpty) {
      await initializeProductStock(codigo, newStock);
    } else {
      await db.update(
        'product_stock',
        {
          'stock': newStock,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'codigo = ?',
        whereArgs: [codigo],
      );
    }
  }

  @override
  Future<StockMovementModel> createMovement(StockMovementModel movement) async {
    final db = await databaseHelper.database;
    await db.insert('stock_movements', movement.toJson());
    return movement;
  }

  @override
  Future<List<StockMovementModel>> getProductMovements(int codigo) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      'stock_movements',
      where: 'productCodigo = ?',
      whereArgs: [codigo],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => StockMovementModel.fromJson(map)).toList();
  }

  @override
  Future<List<StockMovementModel>> getAllMovements({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await databaseHelper.database;
    
    String? where;
    List<dynamic>? whereArgs;

    if (fromDate != null && toDate != null) {
      where = 'createdAt BETWEEN ? AND ?';
      whereArgs = [
        fromDate.toIso8601String(),
        toDate.toIso8601String(),
      ];
    } else if (fromDate != null) {
      where = 'createdAt >= ?';
      whereArgs = [fromDate.toIso8601String()];
    } else if (toDate != null) {
      where = 'createdAt <= ?';
      whereArgs = [toDate.toIso8601String()];
    }

    final maps = await db.query(
      'stock_movements',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => StockMovementModel.fromJson(map)).toList();
  }
}