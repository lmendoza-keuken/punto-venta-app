import 'package:punto_venta_app/features/pos/data/datasources/invoice_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';

abstract class InvoiceRepository {
  Future<bool> sendInvoice(PrintJob job);
}

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remote;

  InvoiceRepositoryImpl({required this.remote});

  @override
  Future<bool> sendInvoice(PrintJob job) async {
    return await remote.sendInvoice(job);
  }
}