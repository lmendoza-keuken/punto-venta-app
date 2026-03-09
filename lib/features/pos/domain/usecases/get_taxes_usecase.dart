import '../../data/models/tax_model.dart';
import '../repositories/tax_repository.dart';

class GetTaxesUsecase {
  final TaxRepository repository;

  GetTaxesUsecase(this.repository);

  Future<List<TaxModel>> call() async {
    return await repository.getTaxes();
  }
}
