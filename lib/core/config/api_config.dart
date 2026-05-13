class ApiConfig {
  static String _companyId = '';
  static String _baseUrl = '';

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
  static String get taxesUrl => '$_baseUrl/taxes/';
  static String get vatCategoriesUrl => '$_baseUrl/vat-categories/';
  static String get fiscalDataUrl => '$_baseUrl/configuration/fiscal-data';


  static void updateCompanyConfig(String companyId, String? baseUrl) {
    _companyId = companyId;

    if (baseUrl != null && baseUrl.isNotEmpty) {
      _baseUrl = baseUrl;
    } else {
      throw Exception('No hay url configurada para esta empresa');
    }
  }

  static void updateCompanyId(String companyId) {
    updateCompanyConfig(companyId, null);
  }

  static String get companyId => _companyId;
}
