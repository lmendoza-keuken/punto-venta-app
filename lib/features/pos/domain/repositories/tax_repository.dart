import 'package:punto_venta_app/features/pos/data/models/tax_model.dart';


abstract class TaxRepository {
  Future<List<TaxModel>> getTaxes();
}
