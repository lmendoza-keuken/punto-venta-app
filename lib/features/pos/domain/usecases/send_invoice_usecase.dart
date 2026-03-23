import 'package:punto_venta_app/features/pos/data/repositories/invoice_repository_impl.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';

class SendInvoiceUseCase {
  final InvoiceRepository repository;

  SendInvoiceUseCase(this.repository);

  Future<Map<String, String?>> call(PrintJob job) async {
    return await repository.sendInvoice(job);
  } 
}