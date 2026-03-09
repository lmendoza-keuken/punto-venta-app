class ApiConfig {
  static String _companyId = '99999999';
  static String _baseUrl = 'http://192.168.0.9:8000';

  static String get productosUrl => '$_baseUrl/articles/';
  static String get preciosArticulosUrl => '$_baseUrl/prices_list/';
  static String get loginUrl => '$_baseUrl/users/login-cashier';
  static String get barcodeUrl => '$_baseUrl/barcodes/';
  static String get categoriesUrl => '$_baseUrl/categories/';
  static String get invoiceUrl => '$_baseUrl/tickets/';
  static String get pdvUrl => '$_baseUrl/pdv/';
  static String get ticketConfigUrl => '$_baseUrl/ticket_config/'; 
  static String get paymentMethodsUrl => '$_baseUrl/payment_methods/';
  static String get configPdvUrl => '$_baseUrl/configuration/';
  static String get branchesUrl => '$_baseUrl/branches/';

  static void updateCompanyConfig(String companyId, String? baseUrl) {
    _companyId = companyId;

    if (baseUrl != null && baseUrl.isNotEmpty) {
      _baseUrl = baseUrl;
    } else {
      _baseUrl =
      // enterprisesLicense/ base url 
          // 'http://orders0.epekuen.com.ar/produccion/$companyId/test/puntoVenta';
          'http://192.168.0.9:8000';
    }
  }

  static void updateCompanyId(String companyId) {
    updateCompanyConfig(companyId, null);
  }

  static String get companyId => _companyId;
}
