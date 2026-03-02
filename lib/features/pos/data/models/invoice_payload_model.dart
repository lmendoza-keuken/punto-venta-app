import 'package:punto_venta_app/core/mocked_taxes_list.dart';
import 'package:punto_venta_app/features/pos/data/models/cart_item_model.dart';
import 'package:punto_venta_app/features/pos/data/models/cart_log_entry_model.dart';
import 'package:punto_venta_app/features/pos/data/models/client_model.dart';
import 'package:punto_venta_app/features/pos/data/models/tax_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';

class InvoicePayload {
  final String? ticketId;
  final String timestamp;
  final int? cashier;
  final Map<String, dynamic>? client;
  final int paymentMethod;
  final double total;
  final List<TaxModel> totalTax;
  final List<Map<String, dynamic>> logItems;
  final String branchNumber;
  final int branchId;
  final int? externalId;
  final String? typeCode;

  InvoicePayload({
    this.ticketId,
    required this.timestamp,
    this.cashier,
    required this.client,
    required this.paymentMethod,
    required this.total,
    required this.totalTax,
    required this.logItems,
    required this.branchNumber,
    required this.branchId,
    this.externalId,
    this.typeCode,
  });

  Map<String, dynamic> toJson() => {
        if (ticketId != null) 'ticketId': ticketId,
        'timestamp': timestamp,
        'cashier': cashier,
        'client': client,
        'paymentMethod': paymentMethod,
        'total': total,
        'branch_number': branchNumber,
        'branch_id': branchId, 
        'totalTax': totalTax.map((t) => t.toJson()).toList(),
        'items': logItems,
      };

  factory InvoicePayload.fromJson(Map<String, dynamic> json) {
    return InvoicePayload(
      ticketId: json['ticketId']?.toString(),
      timestamp: json['timestamp'] as String,
      cashier: json['cashier'] as int?,
      client: json['client'] as Map<String, dynamic>?,
      paymentMethod: json['paymentMethod'] as int,
      total: (json['total'] as num).toDouble(),
      totalTax: (json['totalTax'] as List)
          .map((t) => TaxModel.fromJson(t as Map<String, dynamic>))
          .toList(),
      logItems: (json['items'] as List)
          .map((item) => item as Map<String, dynamic>)
          .toList(),
      branchNumber: json['branch_number']?.toString() ?? '',
      branchId: json['branch_id'] as int? ?? 0,
      externalId: json['external_id'] as int?,
      typeCode: json['type_code'] as String?,
    );
  }

  factory InvoicePayload.fromPrintJob(PrintJob job) {
    Map<String, dynamic>? serializeClient(Client? c) {
      if (c == null) return null;
      final model = ClientModel.fromEntity(c);
      return model.toJson();
    }

    final Map<double, double> totalsByPercentage = {};

    Map<String, dynamic> serializeCartLogItem(CartLogEntry itemLog) {
      try {
        return (itemLog as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        final cartLogItem = CartLogEntryModel.fromEntity(itemLog);
        final itemModel = CartItemModel.fromEntity(itemLog.item);

        final unitPrice = itemModel.product.price ?? 0.0;
        final quantity = itemModel.quantity;
        //
        final weightKg = itemLog.item.weightKg;
        final isWeighted = (itemLog.item.isWeighted == true);
        final taxesList = mockedTaxesList;

        final double taxableBase = isWeighted
            ? (itemModel.pricePerKg ?? unitPrice)
            : unitPrice * quantity;

        final double taxPercentage = (itemModel.iva) + 0.0;
        final double taxAmount = taxableBase * (taxPercentage / 100.0);

        final List<TaxModel> taxes = [
          TaxModel(
            id: taxesList.firstWhere((t) => t.percentage == taxPercentage).id,
            percentage: taxPercentage,
            amount: double.parse(taxAmount.toStringAsFixed(2)),
          ),
        ];

        totalsByPercentage.update(
          taxPercentage,
          (prev) => prev + taxAmount,
          ifAbsent: () => taxAmount,
        );

        return {
          'id': cartLogItem.id,
          'type': cartLogItem.type.toString(),
          'productId': itemModel.product.id,
          'productName': itemModel.product.description,
          'quantity': quantity,
          'discount': 0,
          'unitPrice': unitPrice,
          'priceListId': job.priceListId,
          'taxes': taxes.map((t) => t.toJson()).toList(),
          'is_weighted': isWeighted ? "S" : "N",
          'net_weight': isWeighted ? itemModel.product.netWeight : null,
          'weight': isWeighted ? weightKg ?? 0.0 : null,
        };
      }
    }

    final logItems = job.logItems.map(serializeCartLogItem).toList();

    final totalTax = totalsByPercentage.entries.map((e) {
      final percentage = e.key;
      final amount = e.value;
      return TaxModel(
        id: mockedTaxesList.firstWhere((t) => t.percentage == percentage).id,
        percentage: double.parse(percentage.toStringAsFixed(2)),
        amount: double.parse(amount.toStringAsFixed(2)),
      );
    }).toList();

    return InvoicePayload(
      ticketId: job.ticketId,
      timestamp: job.timestamp.toIso8601String(),
      cashier: job.cashierId,
      client: serializeClient(job.client),
      paymentMethod: job.paymentMethod?.id ?? 0,
      total: job.total,
      totalTax: totalTax,
      logItems: logItems,
      branchNumber: job.branchNumber,
      branchId: job.branchId ?? 0,
    );
  }
}
