class ApiConfig {
  static String _companyId = '99999999';
  static String _baseUrl = 'http://192.168.0.16:8000';

  static String get productosUrl => '$_baseUrl/articles/';
  static String get preciosArticulosUrl => '$_baseUrl/prices_list/';
  static String get loginUrl => '$_baseUrl/users/login';
  static String get barcodeUrl => '$_baseUrl/barcodes/';
  static String get categoriesUrl => '$_baseUrl/categories/';
  static String get invoiceUrl => '$_baseUrl/tickets/';

  static void updateCompanyConfig(String companyId, String? baseUrl) {
    _companyId = companyId;

    if (baseUrl != null && baseUrl.isNotEmpty) {
      _baseUrl = baseUrl;
    } else {
      _baseUrl =
          'http://orders0.epekuen.com.ar/produccion/$companyId/test/puntoVenta';
    }
  }

  static void updateCompanyId(String companyId) {
    updateCompanyConfig(companyId, null);
  }

  static String get companyId => _companyId;
}
