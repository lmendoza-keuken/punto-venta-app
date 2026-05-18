import 'package:punto_venta_app/features/pos/data/models/price_list_type_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/price_list_types_repository.dart';

class FetchPriceListTypesUsecase {
  final PriceListTypesRepository repository;

  FetchPriceListTypesUsecase(this.repository);

  Future<List<PriceListTypeResponseModel>> call() async {
    return await repository.fetchPriceListTypes();
  }
}
