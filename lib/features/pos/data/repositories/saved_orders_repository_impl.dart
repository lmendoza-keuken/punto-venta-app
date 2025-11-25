import 'package:punto_venta_app/features/pos/data/datasources/saved_orders_local_dasource.dart';
import 'package:punto_venta_app/features/pos/data/models/saved_order_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/saved_order.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/saved_orders_repository.dart';

class SavedOrdersRepositoryImpl implements SavedOrdersRepository {
  final SavedOrdersLocalDataSource localDataSource;

  SavedOrdersRepositoryImpl({required this.localDataSource});

  @override
  Future<List<SavedOrder>> getSavedOrders() async {
    final orderModels = await localDataSource.getSavedOrders();
    return orderModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> saveOrder(SavedOrder order) async {
    final orderModel = SavedOrderModel.fromEntity(order);
    await localDataSource.saveOrder(orderModel);
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    await localDataSource.deleteOrder(orderId);
  }

  @override
  Future<SavedOrder?> getOrderById(String orderId) async {
    final orderModel = await localDataSource.getOrderById(orderId);
    return orderModel?.toEntity();
  }
}
