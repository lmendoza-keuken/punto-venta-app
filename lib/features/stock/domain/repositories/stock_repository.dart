import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/stock/domain/entities/stock_movement.dart';

abstract class StockRepository {
  // Gestión de productos
  Future<List<Product>> getAllProducts();
  Future<Product?> getProductByCodigo(int codigo);
  Future<Product> createProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(int codigo);
  
  // Gestión de stock
  Future<int> getProductStock(int codigo);
  Future<void> updateProductStock(int codigo, int newStock);
  Future<void> addStock(int codigo, int quantity, String reason, String userId, String userName);
  Future<void> removeStock(int codigo, int quantity, String reason, String userId, String userName);
  Future<void> adjustStock(int codigo, int newStock, String reason, String userId, String userName);
  
  // Movimientos
  Future<List<StockMovement>> getProductMovements(int codigo);
  Future<List<StockMovement>> getAllMovements({DateTime? fromDate, DateTime? toDate});
}