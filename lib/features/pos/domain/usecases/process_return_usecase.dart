import '../../data/datasources/returns_remote_datasource.dart';
import '../entities/cart_item.dart';

class ProcessReturnUseCase {
  final ReturnsRemoteDataSource dataSource;

  ProcessReturnUseCase(this.dataSource);

  Future<Map<String, dynamic>> call({
    required int reasonId,
    required int deliveryLocationId,
    required List<CartItem> items,
  }) async {
    final List<Map<String, dynamic>> serializedItems = items.map((item) {
      final Map<String, dynamic> itemMap = {
        'product_id': item.product.id,
      };
      if (item.isWeighted == true) {
        itemMap['weight'] = (item.weightKg ?? 0.0).abs();
      } else {
        itemMap['quantity'] = item.quantity.abs();
      }
      return itemMap;
    }).toList();

    final Map<String, dynamic> body = {
      'reason_id': reasonId,
      'delivery_location_id': deliveryLocationId,
      'items': serializedItems,
    };

    return await dataSource.createPartialReturn(body);
  }
}
