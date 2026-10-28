import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_products_usecase.dart';

class GetAllProductsUsecase {
  final GetProductsUsecase getProductsUsecase;

  GetAllProductsUsecase(this.getProductsUsecase);

  Future<List<Product>> call() async {
    return await getProductsUsecase().last;
  }
}
