class ApiConfig {
  static String _companyId = '';
  static String _baseUrl = '';

  static String get _validatedBaseUrl {
    if (_baseUrl.isEmpty) {
      throw Exception('No hay una URL configurada');
    }
    return _baseUrl;
  }

  static String get productosUrl => '$_validatedBaseUrl/articles/';
  static String get pricesListUrl => '$_validatedBaseUrl/prices_list/';
  static String get loginUrl => '$_validatedBaseUrl/users/login-cashier';
  static String get barcodeUrl => '$_validatedBaseUrl/barcodes/';
  static String get categoriesUrl => '$_validatedBaseUrl/categories/';
  static String get invoiceUrl => '$_validatedBaseUrl/tickets/';
  static String get pdvUrl => '$_validatedBaseUrl/pdv/';
  static String get ticketConfigUrl => '$_validatedBaseUrl/ticket_config/';
  static String get paymentMethodsUrl => '$_validatedBaseUrl/payment_methods/';
  static String get configPdvUrl => '$_validatedBaseUrl/configuration/';
  static String get branchesUrl => '$_validatedBaseUrl/branches/';
  static String get taxesUrl => '$_validatedBaseUrl/taxes/';
  static String get vatCategoriesUrl => '$_validatedBaseUrl/vat-categories/';
  static String get fiscalDataUrl =>
      '$_validatedBaseUrl/configuration/fiscal-data';

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
