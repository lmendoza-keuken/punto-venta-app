import 'package:punto_venta_app/features/pos/data/models/fiscal_issuer_data_model.dart';

abstract class FiscalIssuerDataRemoteDatasource {
  Future<FiscalIssuerDataModel> getFiscalIssuerData(int branchId);
}

class FiscalIssuerDataRemoteDatasourceImpl
    implements FiscalIssuerDataRemoteDatasource {
  
  @override
  Future<FiscalIssuerDataModel> getFiscalIssuerData(int branchId) async {
    // Simulando 
    await Future.delayed(const Duration(milliseconds: 500));

    final Map<String, dynamic> mockResponse = {
      'fiscal_name': 'TESTING S.A.',
      'cuit': '20-94244126-7',
      'iibb_cuit': '20942441267',
      'address': 'MARIO BRAVO 176, MAR DEL PLATA, BUENOS AIRES, C.P: 7600',
      'postal_code': '7600',
      'activity_start_date': '01/05/2025',
      'vat_condition': 'IVA RESPONSABLE INSCRIPTO',
      'branch_id': branchId,
    };

    return FiscalIssuerDataModel.fromJson(mockResponse);
  }
}
