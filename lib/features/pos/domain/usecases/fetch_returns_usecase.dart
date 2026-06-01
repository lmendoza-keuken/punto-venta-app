import 'package:intl/intl.dart';
import 'package:punto_venta_app/features/pos/domain/entities/sale_return.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/returns_repository.dart';

class FetchReturnsUsecase {
  final ReturnsRepository repository;

  FetchReturnsUsecase(this.repository);

  Future<List<SaleReturn>> call({DateTime? date}) async {
    final dateParam =
        date != null ? DateFormat('yyyy-MM-dd').format(date) : null;
    return repository.fetchReturns(date: dateParam);
  }
}
