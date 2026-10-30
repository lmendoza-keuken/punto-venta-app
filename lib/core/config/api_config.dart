class ApiConfig {
  static String _companyId = '';
  static String _baseUrl = '';
  static List<String> _baseUrls = [];

  static String get validatedBaseUrl {
    if (_baseUrl.isEmpty) {
      throw Exception('No hay una URL configurada');
    }
    return _baseUrl;
  }

  static List<String> get baseUrls => List.unmodifiable(_baseUrls);

  static String get activeBaseUrl => _baseUrl;

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
  static String get pendingCollectors =>
      '$validatedBaseUrl/settlements/pending/collectors';
  static String get pendingCollectorDetail =>
      '$validatedBaseUrl/settlements/pending/{collector_id}';

  static void updateCompanyConfig(
    String companyId,
    List<String> urls, {
    String? activeUrl,
  }) {
    _companyId = companyId;

    final cleaned = <String>[];
    for (final url in urls) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty && !cleaned.contains(trimmed)) {
        cleaned.add(trimmed);
      }
    }

    if (cleaned.isEmpty) {
      throw Exception('No hay url configurada para esta empresa');
    }

    _baseUrls = cleaned;

    final preferred = activeUrl?.trim();
    if (preferred != null &&
        preferred.isNotEmpty &&
        cleaned.contains(preferred)) {
      _baseUrl = preferred;
    } else {
      _baseUrl = cleaned.first;
    }
  }

  /// Rotates to the next URL in the list. Returns false if there is no alternative.
  static bool switchToNextBaseUrl() {
    if (_baseUrls.length <= 1) {
      return false;
    }

    final currentIndex = _baseUrls.indexOf(_baseUrl);
    final nextIndex =
        currentIndex < 0 ? 0 : (currentIndex + 1) % _baseUrls.length;
    final nextUrl = _baseUrls[nextIndex];

    if (nextUrl == _baseUrl) {
      return false;
    }

    _baseUrl = nextUrl;
    return true;
  }

  static void resetCompanyId() {
    _companyId = '';
    _baseUrl = '';
    _baseUrls = [];
  }

  static String get companyId => _companyId;
}
