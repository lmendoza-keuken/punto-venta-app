class ApiConfig {
  static String baseUrl =
      'http://orders0.epekuen.com.ar/produccion/99999999/test/puntoVenta';

  static String get productosUrl => '$baseUrl/articulos.json';

  static void updateBaseUrl(String newBaseUrl) {
    baseUrl = newBaseUrl;
  }
}
