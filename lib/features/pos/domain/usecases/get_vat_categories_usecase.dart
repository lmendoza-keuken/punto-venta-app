import '../../data/models/vat_category_model.dart';
import '../repositories/vat_category_repository.dart';

class GetVatCategoriesUsecase {
  final VatCategoryRepository repository;

  GetVatCategoriesUsecase(this.repository);

  Future<List<VatCategoryModel>> call() async {
    return await repository.getVatCategories();
  }
}
