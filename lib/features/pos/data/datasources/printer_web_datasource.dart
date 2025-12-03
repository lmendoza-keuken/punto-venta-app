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

  // 58mm = 32 caracteres, 80mm = 48 caracteres
  static const int _lineWidth = 48;

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

  List<int> _buildEscPosCommands(PrintJob printJob) {
    const ESC = 0x1B;
    const GS = 0x1D;
    const LF = 0x0A;
    
    final commands = <int>[];

    // === INICIALIZAR IMPRESORA ===
    commands.addAll([ESC, 0x40]); 

    // === ENCABEZADO CENTRADO ===
    commands.addAll([ESC, 0x61, 0x01]); 
    commands.addAll([ESC, 0x45, 0x01]); 
    commands.addAll(utf8.encode('SOLUCIONES INFORMATICAS'));
    commands.add(LF);
    commands.addAll(utf8.encode('KEUKEN, S.A.'));
    commands.add(LF);
    commands.addAll([ESC, 0x45, 0x00]); 
    commands.addAll(utf8.encode('Sistema de Punto de Venta'));
    commands.add(LF);
    commands.addAll(utf8.encode('Tel: (555) 123-4567'));
    commands.add(LF);
    commands.add(LF);

    // Separador dinámico
    commands.addAll(utf8.encode(_buildSeparator('=')));
    commands.add(LF);

    // === INFORMACIÓN DE LA ORDEN (IZQUIERDA) ===
    commands.addAll([ESC, 0x61, 0x00]);   
    commands.addAll(utf8.encode('Orden: ${printJob.ticketId}'));
    commands.add(LF);
    commands.addAll(utf8.encode('Fecha: ${_formatDate(printJob.timestamp)}'));
    commands.add(LF);
    commands.addAll(utf8.encode('Hora: ${_formatTime(printJob.timestamp)}'));
    commands.add(LF);
    commands.addAll(utf8.encode('Cajero: ${printJob.cashierName}'));
    commands.add(LF);
    
    if (printJob.clientName != null && printJob.clientName!.isNotEmpty) {
      commands.addAll(utf8.encode('Cliente: ${printJob.clientName}'));
      commands.add(LF);
    }

    commands.add(LF);
    commands.addAll(utf8.encode(_buildSeparator('=')));
    commands.add(LF);
    commands.add(LF);

    // === ITEMS ===
    commands.addAll([ESC, 0x61, 0x00]); 
    for (var item in printJob.items) {
      // Nombre del producto
      commands.addAll(utf8.encode(item.product.descripcion));
      commands.add(LF);
      
      // Formatear precios
      final precioUnit = item.product.precio?.formatToCurrency();
      final subtotalValue = (item.quantity * (item.product.precio ?? 0.0)).formatToCurrency();
      final subtotal = subtotalValue;
      
      // Cantidad x Precio
      final line = '  ${item.quantity} x $precioUnit';
      
      // Calcular espacios dinámicamente
      final totalSpaces = _lineWidth - line.length - subtotal.length;
      final spacer = totalSpaces > 0 ? ' ' * totalSpaces : ' ';
      
      commands.addAll(utf8.encode('$line$spacer$subtotal'));
      commands.add(LF);
      commands.add(LF);
    }

    // === SEPARADOR ===
    commands.addAll(utf8.encode(_buildSeparator('-')));
    commands.add(LF);

    // === TOTALES ===
    final subtotalAmount = (printJob.total - printJob.totalTax).formatToCurrency();
    final taxAmount = printJob.totalTax.formatToCurrency();
    final totalAmount = printJob.total.formatToCurrency();

    commands.addAll(_buildLineWithValue('Subtotal:', subtotalAmount));
    commands.addAll(_buildLineWithValue('IVA (21%):', taxAmount));
    commands.add(LF);
    commands.addAll(utf8.encode(_buildSeparator('=')));
    commands.add(LF);
    
    // Total en negrita y doble altura
    commands.addAll([ESC, 0x45, 0x01]); 
    commands.addAll([ESC, 0x21, 0x10]); 
    commands.addAll(_buildLineWithValue('TOTAL:', totalAmount));
    commands.addAll([ESC, 0x21, 0x00]); 
    commands.addAll([ESC, 0x45, 0x00]); 
    commands.add(LF);
    commands.addAll(utf8.encode(_buildSeparator('=')));
    commands.add(LF);
    commands.add(LF);

    // === INFORMACIÓN ADICIONAL ===
    commands.addAll(utf8.encode('Metodo de pago: ${printJob.paymentMethod ?? 'Efectivo'}'));
    commands.add(LF);
    final totalItems = printJob.items.fold(0, (sum, item) => sum + item.quantity);
    commands.addAll(utf8.encode('Total de articulos: $totalItems'));
    commands.add(LF);
    commands.add(LF);

    // === CÓDIGO DE BARRAS ===
    commands.addAll([ESC, 0x61, 0x01]); 
    commands.addAll([GS, 0x48, 0x02]);
    commands.addAll([GS, 0x77, 0x03]); 
    commands.addAll([GS, 0x68, 0xA2]); 
    final ticketIdBytes = utf8.encode(printJob.ticketId);
    commands.addAll([GS, 0x6B, 69, ticketIdBytes.length]);
    commands.addAll(ticketIdBytes);
    commands.add(LF);
    commands.add(LF);

    // === PIE DE PÁGINA ===
    commands.addAll(utf8.encode('Gracias por su compra!'));
    commands.add(LF);
    commands.add(LF);
    commands.add(LF);

    commands.addAll([GS, 0x56, 66, 0x01]); 

    return commands;
  }

  // === MÉTODOS AUXILIARES ===

  String _buildSeparator(String char) {
    return char * _lineWidth;
  }

  List<int> _buildLineWithValue(String label, String value) {
    final totalSpaces = _lineWidth - label.length - value.length;
    final spacer = totalSpaces > 0 ? ' ' * totalSpaces : ' ';
    final line = '$label$spacer$value';
    return [...utf8.encode(line), 0x0A];
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }
}