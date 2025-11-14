import 'package:pos_flutter_app/features/pos/domain/entities/saved_order.dart';

abstract class SavedOrdersRepository {
  Future<List<SavedOrder>> getSavedOrders();
  Future<void> saveOrder(SavedOrder order);
  Future<void> deleteOrder(String orderId);
  Future<SavedOrder?> getOrderById(String orderId);
}
