class PrinterConfig {
  final String ip;
  final int port;
  final int timeout;
  final int labelType;

  const PrinterConfig({
    required this.ip,
    required this.port,
    required this.timeout,
    this.labelType = 0,
  });
}