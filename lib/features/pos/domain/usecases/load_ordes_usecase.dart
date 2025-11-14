import 'package:pos_flutter_app/features/pos/domain/entities/saved_order.dart';
import 'package:pos_flutter_app/features/pos/domain/repositories/saved_orders_repository.dart';

class LoadSavedOrdersUsecase {
  final SavedOrdersRepository repository;

  LoadSavedOrdersUsecase(this.repository);

  Future<List<SavedOrder>> call() async {
    final orders = await repository.getSavedOrders();
    // Ordenar por fecha de creación (más recientes primero)
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Future<void> deleteOrder(String orderId) async {
    await repository.deleteOrder(orderId);
  }

  Future<SavedOrder?> getOrderById(String orderId) async {
    return await repository.getOrderById(orderId);
  }
}
