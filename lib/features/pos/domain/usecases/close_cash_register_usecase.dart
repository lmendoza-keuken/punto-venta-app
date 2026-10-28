import 'package:punto_venta_app/features/pos/data/repositories/product_images_repository.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cash_register_status.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/cash_register_repository.dart';

class CloseCashRegisterUseCase {
  final CashRegisterRepository repository;
  final ProductImagesRepository productImagesRepository;

  CloseCashRegisterUseCase(this.repository, this.productImagesRepository);

  Future<CashRegisterStatus> call() async {
    final status = await repository.closeRegister();
    productImagesRepository.clearCache();
    return status;
  }
}
