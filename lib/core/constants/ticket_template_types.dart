enum TicketTemplateType {
  /// Template estándar (por defecto)
  standard,
  
  /// Template SIN desglose de impuestos
  /// Se usa cuando:
  /// - Sucursal con afip_available=false
  blackMarket,
  
  /// Template  CON desglose de impuestos
  /// Se usa cuando:
  /// - Sucursal con afip_available=true
  /// - Si cliente.tax_details=true → muestra desglose completo
  /// - Si cliente.tax_details=false → sin desglose
  whiteMarket;
}
