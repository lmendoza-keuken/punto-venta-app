import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';

abstract class PrinterWebDatasource {
  Future<bool> connect(PrinterConfig config);
  Future<bool> disconnect();
  Future<bool> printTicket(PrintJob printJob);
  Future<bool> isConnected();
}

class PrinterWebDatasourceImpl implements PrinterWebDatasource {
  final String proxyUrl;
  bool _isConnected = false;

  PrinterWebDatasourceImpl({
    this.proxyUrl = 'http://localhost:3000',
  });

  @override
  Future<bool> connect(PrinterConfig config) async {
    try {
      print('🔌 Conectando al servidor proxy...');
      
      final response = await http
          .get(Uri.parse('$proxyUrl/test-connection'))
          .timeout(Duration(milliseconds: config.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isConnected = data['success'] ?? false;
        
        if (_isConnected) {
          print('✅ Conectado a servidor proxy e impresora');
        } else {
          print('❌ Servidor OK pero impresora no responde: ${data['error']}');
        }
      } else {
        print('❌ Error del servidor: ${response.statusCode}');
        _isConnected = false;
      }

      return _isConnected;
    } catch (e) {
      print('❌ Error al conectar: $e');
      print('💡 Asegúrate de que el servidor esté corriendo:');
      print('   cd printer-proxy && node server.js');
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    _isConnected = false;
    print('🔌 Desconectado');
    return true;
  }

  @override
  Future<bool> isConnected() async {
    return _isConnected;
  }

  @override
  Future<bool> printTicket(PrintJob printJob) async {
    if (!_isConnected) {
      print('❌ No hay conexión con servidor proxy');
      return false;
    }

    try {
      print('📄 Generando ticket...');
      
      // Construir comandos ESC/POS
      final commands = _buildEscPosCommands(printJob);
      
      print('📡 Enviando ${commands.length} bytes al servidor proxy...');

      final response = await http.post(
        Uri.parse('$proxyUrl/print'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'commands': commands}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['success'] == true) {
          print('✅ Ticket impreso correctamente');
          return true;
        } else {
          print('❌ Error del servidor: ${result['error']}');
          return false;
        }
      } else {
        print('❌ Error HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error al imprimir: $e');
      return false;
    }
  }

  /// Construye los comandos ESC/POS para la impresora térmica
  /// Mismo diseño que printer_socket_datasource.dart
  List<int> _buildEscPosCommands(PrintJob printJob) {
    const ESC = 0x1B;
    const GS = 0x1D;
    const LF = 0x0A; // Line Feed
    
    final commands = <int>[];

    // ===== INICIALIZAR IMPRESORA =====
    commands.addAll([ESC, 0x40]); // ESC @ - Reset

    // ===== ALINEACIÓN CENTRO =====
    commands.addAll([ESC, 0x61, 0x01]); // Centrar

    // ===== ENCABEZADO =====
    commands.addAll(utf8.encode('SOLUCIONES INFORMATICAS KEUKEN, S.A.'));
    commands.add(LF);
    
    commands.addAll(utf8.encode('Fecha: ${printJob.timestamp.toString()}'));
    commands.add(LF);
    
    commands.addAll(utf8.encode('Cajero: ${printJob.cashierName}'));
    commands.add(LF);
    
    if (printJob.clientName != null && printJob.clientName!.isNotEmpty) {
      commands.addAll(utf8.encode('Cliente: ${printJob.clientName}'));
      commands.add(LF);
    }

    commands.addAll(utf8.encode('Ticket: ${printJob.ticketId}'));
    commands.add(LF);
    
    commands.addAll(utf8.encode('================================'));
    commands.add(LF);

    // ===== ITEMS DEL CARRITO =====
    for (var item in printJob.items) {
      commands.addAll(utf8.encode(item.product.descripcion));
      commands.add(LF);
      
      commands.addAll(utf8.encode('Cant: ${item.quantity} x \$${item.product.precio.formatToCurrency()}'));
      commands.add(LF);
      
      final subtotal = (item.quantity * item.product.precio).formatToCurrency();
      commands.addAll(utf8.encode('Subtotal: \$$subtotal'));
      commands.add(LF);
      
      commands.addAll(utf8.encode('--------------------------------'));
      commands.add(LF);
    }

    // ===== TOTAL =====
    commands.addAll(utf8.encode('================================'));
    commands.add(LF);
    
    commands.addAll(utf8.encode('TOTAL: \$${printJob.total.formatToCurrency()}'));
    commands.add(LF);
    
    commands.addAll(utf8.encode('================================'));
    commands.add(LF);

    // ===== CÓDIGO DE BARRAS =====
    // Configurar posición HRI (debajo del código)
    commands.addAll([GS, 0x48, 0x02]); // GS H 2
    
    // Configurar ancho del código de barras
    commands.addAll([GS, 0x77, 0x03]); // GS w 3
    
    // Configurar altura del código de barras
    commands.addAll([GS, 0x68, 0xA2]); // GS h 162 (0xA2)
    
    // Imprimir código de barras CODE39 (tipo 69)
    final ticketIdBytes = utf8.encode(printJob.ticketId);
    commands.addAll([GS, 0x6B, 69, ticketIdBytes.length]);
    commands.addAll(ticketIdBytes);
    commands.add(LF);

    // ===== CORTAR PAPEL =====
    commands.addAll([GS, 0x56, 66, 0x01]); // GS V 66 1 - Corte parcial

    return commands;
  }
}