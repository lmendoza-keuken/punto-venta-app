import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';

abstract class PrinterLocalDataSource {
  Future<PrinterConfig> getPrinterConfig();
  Future<void> savePrinterConfig(PrinterConfig config);
}

class PrinterLocalDataSourceImpl implements PrinterLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _key = 'PRINTER_CONFIG';

  PrinterLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<PrinterConfig> getPrinterConfig() async {
    final jsonString = sharedPreferences.getString(_key);
    if (jsonString == null) {
      // return const PrinterConfig(ip: '192.168.0.230', port: 9100, timeout: 10000);
      return const PrinterConfig(ip: '', port: 9100, timeout: 10000);
    }
    final Map<String, dynamic> data =
        json.decode(jsonString) as Map<String, dynamic>;
    return PrinterConfig(
      ip: data['ip']?.toString() ?? '',
      port: (data['port'] is int)
          ? data['port'] as int
          : int.tryParse(data['port']?.toString() ?? '') ?? 9100,
      timeout: (data['timeout'] is int)
          ? data['timeout'] as int
          : int.tryParse(data['timeout']?.toString() ?? '') ?? 20000,
      labelType: (data['labelType'] is int)
          ? data['labelType'] as int
          : int.tryParse(data['labelType']?.toString() ?? '') ?? 0,
    );
  }

  @override
  Future<void> savePrinterConfig(PrinterConfig config) async {
    final jsonString = json.encode({
      'ip': config.ip,
      'port': config.port,
      'timeout': config.timeout,
      'labelType': config.labelType,
    });
    await sharedPreferences.setString(_key, jsonString);
  }
}
