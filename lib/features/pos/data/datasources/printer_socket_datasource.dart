import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';

abstract class PrinterSocketDatasource {
  Future<bool> connect(PrinterConfig config);
  Future<bool> disconnect();
  Future<bool> printTicket(PrintJob printJob);
  Future<bool> isConnected();
}

class PrinterSocketDatasourceImpl implements PrinterSocketDatasource {
  Socket? _socket;
  bool _isConnected = false;

  // 58mm = 32 caracteres, 80mm = 48 caracteres
  static const int _lineWidth = 48;

  @override
  Future<bool> connect(PrinterConfig config) async {
    try {
      _socket = await Socket.connect(config.ip, config.port)
          .timeout(Duration(milliseconds: config.timeout));
      _isConnected = true;

      await _initPrinter();

      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      await _socket?.close();
      _socket = null;
      _isConnected = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isConnected() async {
    return _isConnected && _socket != null;
  }

  @override
  Future<bool> printTicket(PrintJob printJob) async {
    if (!_isConnected || _socket == null) return false;

    try {
      // === ENCABEZADO CENTRADO ===
      await _selectAlignment(1);
      await _setBold(true);
      await _printText("SOLUCIONES INFORMATICAS");
      await _printAndFeedLine();
      await _printText("KEUKEN, S.A.");
      await _printAndFeedLine();
      await _setBold(false);
      await _printText("Sistema de Punto de Venta");
      await _printAndFeedLine();
      await _printText("Tel: (555) 123-4567");
      await _printAndFeedLine();
      await _printAndFeedLine();

      // Separador dinámico
      await _printText(_buildSeparator('_'));
      await _printAndFeedLine();
      await _printAndFeedLine();

      // === INFORMACIÓN DE LA ORDEN (IZQUIERDA) ===
      await _selectAlignment(0);
      await _printText("Orden: ${printJob.ticketId}");
      await _printAndFeedLine();
      await _printText("Fecha: ${_formatDate(printJob.timestamp)}");
      await _printAndFeedLine();
      await _printText("Hora: ${_formatTime(printJob.timestamp)}");
      await _printAndFeedLine();
      await _printText("Cajero: ${printJob.cashierName}");
      await _printAndFeedLine();

      if (printJob.clientName != null && printJob.clientName!.isNotEmpty) {
        await _printText("Cliente: ${printJob.clientName}");
        await _printAndFeedLine();
      }

      await _printText(_buildSeparator('_'));
      await _printAndFeedLine();
      await _printAndFeedLine();

      // === ITEMS ===
      await _selectAlignment(0);
      for (final item in printJob.items) {
        await _printText(item.product.description);
        await _printAndFeedLine();

        if (item.isWeighted == true) {
          final weightKg = (item.weightKg ?? 0.0);
          final pricePerKg = (item.pricePerKg ?? item.product.precio ?? 0.0);
  

          final subtotalValue = pricePerKg.formatToCurrency();
          final weightLabel = "$weightKg kg";
          final priceLabel = item.product.precio?.formatToCurrency();

          final lineLeft = "  $weightLabel x $priceLabel";
          final totalSpacesLeft =
              _lineWidth - lineLeft.length - subtotalValue.length;
          final spacerLeft = totalSpacesLeft > 0 ? ' ' * totalSpacesLeft : ' ';
          await _printText("$lineLeft$spacerLeft$subtotalValue");
          await _printAndFeedLine();
        } else {
          final unitPrice = (item.pricePerKg ?? item.product.precio ?? 0.0)
              .formatToCurrency();
          final subtotalValue =
              (item.quantity * (item.pricePerKg ?? item.product.precio ?? 0.0))
                  .formatToCurrency();
          final line = "  ${item.quantity} x $unitPrice";

          final totalSpaces = _lineWidth - line.length - subtotalValue.length;
          final spacer = totalSpaces > 0 ? ' ' * totalSpaces : ' ';

          await _printText("$line$spacer$subtotalValue");
          await _printAndFeedLine();
        }
      }

      // === SEPARADOR ===
      await _printText(_buildSeparator('-'));
      await _printAndFeedLine();

      // === TOTALES ===
      final subtotalAmount =
          (printJob.total - printJob.totalTax).formatToCurrency();
      final taxAmount = printJob.totalTax.formatToCurrency();
      final totalAmount = printJob.total.formatToCurrency();

      await _printLineWithValue("Subtotal:", subtotalAmount);
      await _printLineWithValue("IVA:", taxAmount);
      await _printText(_buildSeparator('_'));
      await _printAndFeedLine();

      // Total en negrita
      await _printAndFeedLine();
      await _setBold(true);
      await _setDoubleHeight(true);
      await _printLineWithValue("TOTAL:", totalAmount);
      await _setDoubleHeight(false);
      await _setBold(false);
      await _printText(_buildSeparator('_'));
      await _printAndFeedLine();

      // === INFORMACIÓN ADICIONAL ===
      await _printAndFeedLine();
      await _printText(
          "Metodo de pago: ${printJob.paymentMethod ?? 'Efectivo'}");
      await _printAndFeedLine();
      final totalItems =
          printJob.items.fold(0, (sum, item) => sum + item.quantity);
      await _printText("Total de articulos: $totalItems");
      await _printAndFeedLine();
      await _printAndFeedLine();

      // === CÓDIGO DE BARRAS ===
      await _selectAlignment(1);
      await _printBarcode(69, printJob.ticketId);
      await _printAndFeedLine();
      await _printAndFeedLine();

      // === PIE DE PÁGINA ===
      await _printText("Gracias por su compra!");
      await _printAndFeedLine();
      await _printAndFeedLine();
      await _printAndFeedLine();

      // Cortar papel
      await _selectCutPaperModeAndCutPaper(66, 1);

      return true;
    } catch (e) {
      print('❌ Error al imprimir: $e');
      return false;
    }
  }

  // === MÉTODOS AUXILIARES ===

  String _buildSeparator(String char) {
    return char * _lineWidth;
  }

  Future<void> _printLineWithValue(String label, String value) async {
    final totalSpaces = _lineWidth - label.length - value.length;
    final spacer = totalSpaces > 0 ? ' ' * totalSpaces : ' ';
    await _printText("$label$spacer$value");
    await _printAndFeedLine();
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }

  Future<bool> _initPrinter() async {
    try {
      await _sendData(Uint8List.fromList([0x1B, 0x40]));

      await _selectHRICharacterPrintPosition(2);
      await _setBarcodeWidth(3);
      await _setBarcodeHeight(162);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _sendData(Uint8List data) async {
    try {
      _socket?.add(data);
      await _socket?.flush();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _printText(String text) async {
    try {
      final data = utf8.encode(text);
      return await _sendData(Uint8List.fromList(data));
    } catch (e) {
      return false;
    }
  }

  Future<bool> _printAndFeedLine() async {
    return await _sendData(Uint8List.fromList([0x0A]));
  }

  Future<bool> _selectAlignment(int alignment) async {
    // 0 = Izquierda, 1 = Centro, 2 = Derecha
    return await _sendData(Uint8List.fromList([0x1B, 0x61, alignment]));
  }

  Future<bool> _setBold(bool enable) async {
    return await _sendData(Uint8List.fromList([0x1B, 0x45, enable ? 1 : 0]));
  }

  Future<bool> _setDoubleHeight(bool enable) async {
    return await _sendData(
        Uint8List.fromList([0x1B, 0x21, enable ? 0x10 : 0x00]));
  }

  Future<bool> _setBarcodeWidth(int width) async {
    return await _sendData(Uint8List.fromList([0x1D, 0x77, width]));
  }

  Future<bool> _setBarcodeHeight(int height) async {
    return await _sendData(Uint8List.fromList([0x1D, 0x68, height]));
  }

  Future<bool> _selectHRICharacterPrintPosition(int code) async {
    return await _sendData(Uint8List.fromList([0x1D, 0x48, code]));
  }

  Future<bool> _printBarcode(int codeType, String codeToPrint) async {
    try {
      await _sendData(
          Uint8List.fromList([0x1D, 0x6B, codeType, codeToPrint.length]));
      return await _printText(codeToPrint);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _selectCutPaperModeAndCutPaper(int m, int n) async {
    return await _sendData(Uint8List.fromList([0x1D, 0x56, m, n]));
  }
}
