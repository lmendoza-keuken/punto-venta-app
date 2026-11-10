/// Destino de impresión.
///
/// - [auto]: si hay térmica integrada (PTA0130), usarla; si no, IP.
/// - [builtin]: forzar impresora integrada.
/// - [network]: forzar ESC/POS por IP.
enum PrinterOutputMode { auto, builtin, network }

class PrinterConfig {
  final String ip;
  final int port;
  final int timeout;
  final int labelType;
  final PrinterOutputMode outputMode;

  const PrinterConfig({
    required this.ip,
    required this.port,
    required this.timeout,
    this.labelType = 0,
    this.outputMode = PrinterOutputMode.auto,
  });

  PrinterConfig copyWith({
    String? ip,
    int? port,
    int? timeout,
    int? labelType,
    PrinterOutputMode? outputMode,
  }) {
    return PrinterConfig(
      ip: ip ?? this.ip,
      port: port ?? this.port,
      timeout: timeout ?? this.timeout,
      labelType: labelType ?? this.labelType,
      outputMode: outputMode ?? this.outputMode,
    );
  }
}
