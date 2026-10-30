import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/base_ticket_template.dart';

/// Ticket de descarte / mercadería en mal estado.
/// Solo: título, cajero, productos y motivo.
class DisposeTicketTemplate extends BaseTicketTemplate {
  DisposeTicketTemplate({required super.printJob});

  @override
  Future<List<TicketCommand>> build() async {
    final commands = <TicketCommand>[];

    commands.add(TicketCommand.alignment(TicketAlignment.center));
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.text('DESCARTE DE STOCK'));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.text('MERCADERIA EN MAL ESTADO'));
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.text(buildSeparator('=')));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());

    commands.add(TicketCommand.alignment(TicketAlignment.left));
    commands.add(TicketCommand.lineWithValue(
      'Fecha: ${formatDate(printJob.timestamp)}',
      'Hora: ${formatTime(printJob.timestamp)}',
    ));
    commands.add(TicketCommand.text('Cajero: ${printJob.cashierName ?? '-'}'));
    if (printJob.cashierId != null) {
      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.text('ID Cajero: ${printJob.cashierId}'));
    }
    commands.add(TicketCommand.feedLine());

    if (printJob.disposeReason != null &&
        printJob.disposeReason!.isNotEmpty) {
      commands.add(TicketCommand.text('Motivo: ${printJob.disposeReason}'));
      commands.add(TicketCommand.feedLine());
    }

    commands.add(TicketCommand.text(buildSeparator('_')));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());

    commands.addAll(_buildDisposeItems());

    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.alignment(TicketAlignment.center));
    commands.add(TicketCommand.text(buildSeparator('-')));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.cutPaper());

    return commands;
  }

  List<TicketCommand> _buildDisposeItems() {
    final commands = <TicketCommand>[
      TicketCommand.alignment(TicketAlignment.left),
      TicketCommand.bold(true),
      TicketCommand.text('Productos:'),
      TicketCommand.bold(false),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
    ];

    final entries = printJob.logItems.isNotEmpty
        ? printJob.logItems
        : printJob.items
            .map(
              (item) => CartLogEntry(
                id: '',
                type: CartActionType.add,
                item: item,
                timestamp: printJob.timestamp,
              ),
            )
            .toList();

    for (final entry in entries) {
      if (entry.type == CartActionType.remove) continue;
      final item = entry.item;
      final productName =
          item.product.name.length > BaseTicketTemplate.lineWidth - 2
              ? '${item.product.name.substring(0, BaseTicketTemplate.lineWidth - 5)}...'
              : item.product.name;

      commands.add(TicketCommand.text(productName));
      commands.add(TicketCommand.feedLine());

      final isWeighted = item.isWeighted == true;
      final qtyLabel = isWeighted
          ? '${(item.weightKg ?? 0.0).toStringAsFixed(3)} kg'
          : '${item.quantity}';
      commands.add(TicketCommand.text('  Cant: $qtyLabel'));
      commands.add(TicketCommand.feedLine());
    }

    return commands;
  }
}
