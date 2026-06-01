class ApiConfig {
  static String _companyId = '';
  static String _baseUrl = '';

  static String get validatedBaseUrl {
    if (_baseUrl.isEmpty) {
      throw Exception('No hay una URL configurada');
    }
    return _baseUrl;
  }

  static String get productosUrl => '$validatedBaseUrl/articles/';
  static String get pricesListUrl => '$validatedBaseUrl/prices_list/';
  static String get loginUrl => '$validatedBaseUrl/users/login-cashier';
  static String get barcodeUrl => '$validatedBaseUrl/barcodes/';
  static String get categoriesUrl => '$validatedBaseUrl/categories/';
  static String get invoiceUrl => '$validatedBaseUrl/tickets/';
  static String get pdvUrl => '$validatedBaseUrl/pdv/';
  static String get ticketConfigUrl => '$validatedBaseUrl/ticket_config/';
  static String get paymentMethodsUrl => '$validatedBaseUrl/payment_methods/';
  static String get configPdvUrl => '$validatedBaseUrl/configuration/';
  static String get branchesUrl => '$validatedBaseUrl/branches/';
  static String get taxesUrl => '$validatedBaseUrl/taxes/';
  static String get vatCategoriesUrl => '$validatedBaseUrl/vat-categories/';
  static String get fiscalDataUrl =>
      '$validatedBaseUrl/configuration/fiscal-data';
  static String get returnsReasonsUrl => '$validatedBaseUrl/returns/reasons';
  static String get returnsTotalUrl => '$validatedBaseUrl/returns/total';

  static void updateCompanyConfig(String companyId, String? baseUrl) {
    _companyId = companyId;

    if (baseUrl != null && baseUrl.isNotEmpty) {
      _baseUrl = baseUrl;
    } else {
      throw Exception('No hay url configurada para esta empresa');
    }
  }

  static void resetCompanyId() {
    _companyId = '';
    _baseUrl = '';
  }

  static String get companyId => _companyId;
}
