import 'dart:typed_data';

import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pta_thermal_printer.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/base_ticket_template.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/ticket_template_builder.dart';

/// Backend de impresión para la térmica integrada (PTA0130).
///
/// Reutiliza [TicketTemplateBuilder] → [TicketCommand] (mismos templates que IP).
class PrinterBuiltinDatasource {
  bool _connected = false;

  Future<bool> isAvailable() => PtaThermalPrinter.isAvailable();

  Future<bool> connect() async {
    final ok = await PtaThermalPrinter.connect();
    _connected = ok;
    return ok;
  }

  Future<bool> disconnect() async {
    final ok = await PtaThermalPrinter.disconnect();
    _connected = false;
    return ok;
  }

  Future<bool> isConnected() async => _connected;

  Future<bool> printTicket(PrintJob printJob) async {
    try {
      final templateBuilder = TicketTemplateBuilder(printJob: printJob);
      final commands = await templateBuilder.build();
      final serialized = commands.map(_serializeCommand).toList();
      return await PtaThermalPrinter.printCommands(serialized);
    } catch (e, st) {
      AppLogger.error('PrinterBuiltinDatasource.printTicket', e, st);
      rethrow;
    }
  }

  Future<bool> printCommands(List<TicketCommand> commands) async {
    try {
      final serialized = commands.map(_serializeCommand).toList();
      return await PtaThermalPrinter.printCommands(serialized);
    } catch (e, st) {
      AppLogger.error('PrinterBuiltinDatasource.printCommands', e, st);
      rethrow;
    }
  }

  static Map<String, dynamic> _serializeCommand(TicketCommand command) {
    switch (command.type) {
      case TicketCommandType.text:
        return {'type': 'text', 'value': command.value as String};
      case TicketCommandType.feedLine:
        return {'type': 'feedLine'};
      case TicketCommandType.alignment:
        final align = command.value as TicketAlignment;
        return {
          'type': 'alignment',
          'value': switch (align) {
            TicketAlignment.left => 'left',
            TicketAlignment.center => 'center',
            TicketAlignment.right => 'right',
          },
        };
      case TicketCommandType.bold:
        return {'type': 'bold', 'value': command.value as bool};
      case TicketCommandType.doubleHeight:
        return {'type': 'doubleHeight', 'value': command.value as bool};
      case TicketCommandType.doubleWidth:
        return {'type': 'doubleWidth', 'value': command.value as bool};
      case TicketCommandType.textSize:
        final data = command.value as Map<String, dynamic>;
        return {
          'type': 'textSize',
          'width': data['width'] as int,
          'height': data['height'] as int,
        };
      case TicketCommandType.lineWithValue:
        final data = command.value as Map<String, String>;
        return {
          'type': 'lineWithValue',
          'label': data['label']!,
          'value': data['value']!,
        };
      case TicketCommandType.image:
        final img = command.value as PrintImageData;
        return {
          'type': 'image',
          'bytes': Uint8List.fromList(img.bytes),
          'imageSize': img.imageSize,
        };
      case TicketCommandType.barcode:
        return {'type': 'barcode', 'code': command.value as String};
      case TicketCommandType.barcodeWithType:
        final data = command.value as Map<String, dynamic>;
        return {
          'type': 'barcodeWithType',
          'code': data['code'] as String,
          'barcodeType': data['type'] as int,
        };
      case TicketCommandType.setBarcodeHeight:
        return {
          'type': 'setBarcodeHeight',
          'value': command.value as int,
        };
      case TicketCommandType.setBarcodeWidth:
        return {
          'type': 'setBarcodeWidth',
          'value': command.value as int,
        };
      case TicketCommandType.setBarcodeHRIPosition:
        return {
          'type': 'setBarcodeHRIPosition',
          'value': command.value as int,
        };
      case TicketCommandType.cutPaper:
        return {'type': 'cutPaper'};
    }
  }
}
