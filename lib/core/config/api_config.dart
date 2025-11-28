class ApiConfig {
  static String _companyId = '99999999';
  static String _baseUrl = 'http://orders0.epekuen.com.ar/produccion/$_companyId/test/puntoVenta';

  static String get productosUrl => '$_baseUrl/articulos.json';
  static String get usersUrl => '$_baseUrl/users.json';

  static void updateCompanyId(String companyId) {
    _companyId = companyId;
    _baseUrl = 'http://orders0.epekuen.com.ar/produccion/$companyId/test/puntoVenta';
  }

  static String get companyId => _companyId;
}