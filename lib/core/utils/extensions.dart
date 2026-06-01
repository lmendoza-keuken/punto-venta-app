import 'package:intl/intl.dart';

extension FormatCurrency on double {
  String formatToCurrency([String? currencyCode]) {
    final code = (currencyCode ?? 'ARS').toUpperCase();

    late NumberFormat format;

    switch (code) {
      case 'USD':
        format = NumberFormat('#,##0.00', 'en_US');
        break;
      case 'ARS':
      default:
        format = NumberFormat('#,##0.00', 'es_AR');
        break;
    }

    return '\$ ${format.format(this)}';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
