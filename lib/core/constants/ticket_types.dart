class TicketType {
  /// Factura (Venta)
  static const String factura = 'FAC';
  
  /// Nota de Crédito
  static const String notaCredito = 'N.C';
  
  /// Verifica si un tipo es una factura
  static bool isFactura(String? typeCode) => typeCode == factura;
  
  /// Verifica si un tipo es una nota de crédito
  static bool isNotaCredito(String? typeCode) => typeCode == notaCredito;
}
