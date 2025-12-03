class ApiConfig {
  static String _companyId = '99999999';
  static String _baseUrl = 'http://orders0.epekuen.com.ar/produccion/$_companyId/test/puntoVenta';

  static String get productosUrl => '$_baseUrl/articulos.json';
  static String get preciosArticulosUrl => '$_baseUrl/preciosarticulos.json';
  static String get usersUrl => '$_baseUrl/users.json';
  static String get barcode => '$_baseUrl/barcode.json'; 



  static String get clientsUrl => '$_baseUrl/clientes.json'; // Por el momento no se usa
  static String get stockUrl => '$_baseUrl/stock.json'; // Por el momento no se usa

  static String get invoiceUrl => '';

  static void updateCompanyConfig(String companyId, String? baseUrl) {
    _companyId = companyId;
    
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _baseUrl = baseUrl;
    } else {
      _baseUrl = 'http://orders0.epekuen.com.ar/produccion/$companyId/test/puntoVenta';
    }
  }

  static void updateCompanyId(String companyId) {
    updateCompanyConfig(companyId, null);
  }

  static String get companyId => _companyId;
}