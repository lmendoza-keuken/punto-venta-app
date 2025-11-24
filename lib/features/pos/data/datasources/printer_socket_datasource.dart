import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pos_flutter_app/core/utils/extensions.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/print_job.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/printer_config.dart';

abstract class PrinterSocketDatasource {
  Future<bool> connect(PrinterConfig config);
  Future<bool> disconnect();
  Future<bool> printTicket(PrintJob printJob);
  Future<bool> isConnected();
}

class PrinterSocketDatasourceImpl implements PrinterSocketDatasource {
  Socket? _socket;
  bool _isConnected = false;

  @override
  Future<bool> connect(PrinterConfig config) async {
    try {
      _socket = await Socket.connect(config.ip, config.port)
          .timeout(Duration(milliseconds: config.timeout));
      _isConnected = true;
      
      // Inicializar impresora
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
      // Encabezado
      await _printText("SOLUCIONES INFORMATICAS KEUKEN, S.A.");
      await _printAndFeedLine();
      await _printText("Fecha: ${printJob.timestamp.toString()}");
      await _printAndFeedLine();
      await _printText("Cajero: ${printJob.cashierName}");
      await _printAndFeedLine();
      
      if (printJob.clientName != null) {
        await _printText("Cliente: ${printJob.clientName}");
        await _printAndFeedLine();
      }

      await _printText("Ticket: ${printJob.ticketId}");
      await _printAndFeedLine();
      await _printText("================================");
      await _printAndFeedLine();

      // Items del carrito
      for (final item in printJob.items) {
        await _printText("${item.product.descripcion}");
        await _printAndFeedLine();
        await _printText("Cant: ${item.quantity} x \$${item.product.precio.formatToCurrency()}");
        await _printAndFeedLine();
        await _printText("Subtotal: \$${(item.quantity * item.product.precio).formatToCurrency()}");
        await _printAndFeedLine();
        await _printText("--------------------------------");
        await _printAndFeedLine();
      }

      // Total
      await _printText("================================");
      await _printAndFeedLine();
      await _printText("TOTAL: \$${printJob.total.formatToCurrency()}");
      await _printAndFeedLine();
      await _printText("================================");
      await _printAndFeedLine();

      // Código de barras del ticket
      await _printBarcode(69, printJob.ticketId);
      await _printAndFeedLine();

      // Cortar papel
      await _selectCutPaperModeAndCutPaper(66, 1);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _initPrinter() async {
    try {
      // Inicializar impresora (ESC @)
      await _sendData(Uint8List.fromList([0x1B, 0x40]));
      
      // Seleccionar alineación centro
      await _selectAlignment(1);
      
      // Configurar código de barras
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
    return await _sendData(Uint8List.fromList([0x1B, 0x61, alignment]));
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
      await _sendData(Uint8List.fromList([0x1D, 0x6B, codeType, codeToPrint.length]));
      return await _printText(codeToPrint);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _selectCutPaperModeAndCutPaper(int m, int n) async {
    return await _sendData(Uint8List.fromList([0x1D, 0x56, m, n]));
  }
}