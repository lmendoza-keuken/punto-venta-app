import 'package:punto_venta_app/features/pos/data/models/price_list_type_response_model.dart';

abstract class PriceListTypesRepository {
  Future<List<PriceListTypeResponseModel>> fetchPriceListTypes();
} 
