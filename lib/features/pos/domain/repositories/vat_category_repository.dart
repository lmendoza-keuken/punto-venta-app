import 'package:punto_venta_app/features/pos/data/models/vat_category_model.dart';

abstract class VatCategoryRepository {
  Future<List<VatCategoryModel>> getVatCategories();
}
