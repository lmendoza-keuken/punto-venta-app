import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'punto_venta.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de stock (almacena el stock local de cada producto)
    await db.execute('''
      CREATE TABLE product_stock (
        codigo INTEGER PRIMARY KEY,
        stock INTEGER NOT NULL DEFAULT 0,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Tabla de movimientos de stock
    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        productCodigo INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        previousStock INTEGER NOT NULL,
        newStock INTEGER NOT NULL,
        reason TEXT,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (productCodigo) REFERENCES product_stock (codigo)
      )
    ''');

    // Índices
    await db.execute(
        'CREATE INDEX idx_stock_movements_product ON stock_movements(productCodigo)');
    await db.execute(
        'CREATE INDEX idx_stock_movements_date ON stock_movements(createdAt)');

    // Tabla de configuración de PDV
    await db.execute('''
      CREATE TABLE pdv_config (
        id TEXT PRIMARY KEY,
        showSubtotalAndTax INTEGER NOT NULL DEFAULT 0,
        showPricesWithTax INTEGER NOT NULL DEFAULT 1,
        lastUpdated TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migración de versión 1 a 2: agregar tabla pdv_config
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE pdv_config (
          id TEXT PRIMARY KEY,
          pdvId TEXT NOT NULL,
          showSubtotalAndTax INTEGER NOT NULL DEFAULT 0,
          showPricesWithTax INTEGER NOT NULL DEFAULT 1,
          lastUpdated TEXT NOT NULL
        )
      ''');
    }

    // Migración de versión 2 a 3: eliminar columna pdvId de pdv_config
    if (oldVersion < 3) {
      // SQLite no permite eliminar columnas directamente, necesitamos recrear la tabla
      await db.execute('DROP TABLE IF EXISTS pdv_config');
      await db.execute('''
        CREATE TABLE pdv_config (
          id TEXT PRIMARY KEY,
          showSubtotalAndTax INTEGER NOT NULL DEFAULT 0,
          showPricesWithTax INTEGER NOT NULL DEFAULT 1,
          lastUpdated TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> clearAllTables() async {
    final db = await database;
    await db.delete('stock_movements');
    await db.delete('product_stock');
    await db.delete('pdv_config');
  }
}
