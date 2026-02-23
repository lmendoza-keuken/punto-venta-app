import 'package:punto_venta_app/features/pos/data/datasources/completed_orders_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/completed_orders_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/completed_order_model.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/pos/data/models/product_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/completed_orders_repository.dart';

class CompletedOrdersRepositoryImpl implements CompletedOrdersRepository {
  final CompletedOrdersLocalDataSource localDataSource;
  final CompletedOrdersRemoteDataSource? remoteDataSource;

  CompletedOrdersRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
  });

  @override
  Future<List<CompletedOrder>> getCompletedOrders() async {
    try {
      
      final orderModels = await localDataSource.getCompletedOrders();
      final orders = orderModels.map((model) => model.toEntity()).toList();
      orders.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return orders;
    } catch (e) {
      throw Exception('Error al obtener órdenes completadas: $e');
    }
  }

  @override
  Future<void> saveCompletedOrder(CompletedOrder order) async {
    try {
      final orderModel = CompletedOrderModel.fromEntity(order);
      await localDataSource.saveCompletedOrder(orderModel);
    } catch (e) {
      throw Exception('Error al guardar orden completada: $e');
    }
  }

  @override
  Future<List<CompletedOrder>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final orderModels =
          await localDataSource.getOrdersByDateRange(startDate, endDate);
      final orders = orderModels.map((model) => model.toEntity()).toList();
      orders.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return orders;
    } catch (e) {
      throw Exception('Error al obtener órdenes por rango de fechas: $e');
    }
  }

  @override
  Future<CompletedOrder?> getOrderById(String orderId) async {
    try {
      final orderModel = await localDataSource.getOrderById(orderId);
      return orderModel?.toEntity();
    } catch (e) {
      throw Exception('Error al obtener orden por ID: $e');
    }
  }

  @override
  Future<double> getTotalSalesByDate(DateTime date) async {
    try {
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final orders = await getOrdersByDateRange(startDate, endDate);

      double totalSales = 0.0;
      for (final order in orders) {
        totalSales += order.total;
      }

      return totalSales;
    } catch (e) {
      throw Exception('Error al calcular ventas totales por fecha: $e');
    }
  }

  // Remote methods
  @override
  Future<List<CompletedOrder>> getCompletedOrdersFromRemote({int skip = 0, int limit = 10}) async {
    if (remoteDataSource == null) {
      throw Exception('Remote data source not available');
    }

    try {
      final invoicePayloads = await remoteDataSource!.getAllOrders(skip: skip, limit: limit);
      return invoicePayloads
          .map((payload) => _convertInvoicePayloadToCompletedOrder(payload))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener órdenes desde el servidor: $e');
    }
  }

  @override
  Future<List<CompletedOrder>> getOrdersByDateRangeFromRemote(
      DateTime startDate, {DateTime? endDate, int skip = 0, int limit = 10}) async {
    if (remoteDataSource == null) {
      throw Exception('Remote data source not available');
    }

    try {
      final invoicePayloads =
          await remoteDataSource!.getOrdersByDateRange(startDate, endDate: endDate, skip: skip, limit: limit);
      final orders = invoicePayloads
          .map((payload) => _convertInvoicePayloadToCompletedOrder(payload))
          .toList();
      orders.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return orders;
    } catch (e) {
      throw Exception(
          'Error al obtener órdenes por rango de fechas desde el servidor: $e');
    }
  }

  @override
  Future<CompletedOrder?> getOrderByIdFromRemote(String orderId) async {
    if (remoteDataSource == null) {
      throw Exception('Remote data source not available');
    }

    try {
      final payload = await remoteDataSource!.getOrderById(orderId);
      if (payload == null) return null;
      return _convertInvoicePayloadToCompletedOrder(payload);
    } catch (e) {
      throw Exception('Error al obtener orden por ID desde el servidor: $e');
    }
  }

  // Helper method to convert InvoicePayload to CompletedOrder
  CompletedOrder _convertInvoicePayloadToCompletedOrder(
      InvoicePayload payload) {
    // Convert log items to CartItems
    final List<CartItem> items = payload.logItems.map((itemJson) {
      // Create a CartItemModel from the JSON
      final productId = itemJson['productId'] as int;
      final productName = itemJson['productName'] as String;
      final quantity = itemJson['quantity'] as int;
      final unitPrice = (itemJson['unitPrice'] as num).toDouble();
      final isWeighted = itemJson['is_weighted'] == 'S';
      final weightKg = isWeighted ? (itemJson['weight'] as num?)?.toDouble() : null;
      final netWeight = isWeighted ? (itemJson['net_weight'] as num?)?.toDouble() : null;
      
      // Extract tax percentage from taxes array
      double taxPercentage = 0.0;
      if (itemJson['taxes'] != null && (itemJson['taxes'] as List).isNotEmpty) {
        final firstTax = (itemJson['taxes'] as List)[0];
        taxPercentage = (firstTax['percentage'] as num?)?.toDouble() ?? 0.0;
      }

      // Create product using ProductModel and convert to entity
      final productModel = ProductModel(
        id: productId,
        description: productName,
        price: unitPrice,
        vat: taxPercentage,
        netWeight: netWeight,
        stock: 0,
        supplierId: 0,
        internalTax: 0,
        isWeighted: isWeighted ? 'S' : 'N',
        categoryId: '',
        suspendedForSale: 'N',
        suspendedForPurchase: 'N',
        isActive: 'S',
        categoryDescription: '',
        isOnSale: 0,
      );

      final cartItem = CartItem(
        product: productModel.toEntity(),
        quantity: quantity,
        iva: taxPercentage,
        isWeighted: isWeighted,
        weightKg: weightKg,
        pricePerKg: isWeighted ? unitPrice : null,
      );

      return cartItem;
    }).toList();

    // Convert log items to CartLogEntry
    final List<CartLogEntry> logs = payload.logItems.map((itemJson) {
      final productId = itemJson['productId'] as int;
      final productName = itemJson['productName'] as String;
      final quantity = itemJson['quantity'] as int;
      final unitPrice = (itemJson['unitPrice'] as num).toDouble();
      final isWeighted = itemJson['is_weighted'] == 'S';
      final weightKg = isWeighted ? (itemJson['weight'] as num?)?.toDouble() : null;
      final netWeight = isWeighted ? (itemJson['net_weight'] as num?)?.toDouble() : null;
      
      double taxPercentage = 0.0;
      if (itemJson['taxes'] != null && (itemJson['taxes'] as List).isNotEmpty) {
        final firstTax = (itemJson['taxes'] as List)[0];
        taxPercentage = (firstTax['percentage'] as num?)?.toDouble() ?? 0.0;
      }

      final productModel = ProductModel(
        id: productId,
        description: productName,
        price: unitPrice,
        vat: taxPercentage,
        netWeight: netWeight,
        stock: 0,
        supplierId: 0,
        internalTax: 0,
        isWeighted: isWeighted ? 'S' : 'N',
        categoryId: '',
        suspendedForSale: 'N',
        suspendedForPurchase: 'N',
        isActive: 'S',
        categoryDescription: '',
        isOnSale: 0,
      );

      final cartItem = CartItem(
        product: productModel.toEntity(),
        quantity: quantity,
        iva: taxPercentage,
        isWeighted: isWeighted,
        weightKg: weightKg,
        pricePerKg: isWeighted ? unitPrice : null,
      );

      return CartLogEntry(
        id: itemJson['id'] as String,
        timestamp: DateTime.parse(payload.timestamp),
        item: cartItem,
        type: CartActionType.add, // Default to add
      );
    }).toList();

    // Calculate total tax
    final totalTax =
        payload.totalTax.fold(0.0, (sum, tax) => sum + (tax.amount ?? 0.0));

    // Calculate total items
    final totalItems = items.fold(0, (sum, item) => sum + item.quantity);

    // Parse payment method
    PaymentMethod? paymentMethod;
    if (payload.paymentMethod == 1) {
      paymentMethod = const PaymentMethod(
        id: 1,
        description: 'Efectivo',
        shortDescription: 'Efectivo',
        deleteAt: '',
      );
    } else if (payload.paymentMethod == 2) {
      paymentMethod = const PaymentMethod(
        id: 2,
        description: 'Tarjeta',
        shortDescription: 'Tarjeta',
        deleteAt: '',
      );
    } else if (payload.paymentMethod == 3) {
      paymentMethod = const PaymentMethod(
        id: 3,
        description: 'Transferencia',
        shortDescription: 'Transfer',
        deleteAt: '',
      );
    }

    // Generate order number from ticketId or timestamp
    final orderNumber = payload.ticketId ?? 
        'ORD-${DateTime.parse(payload.timestamp).millisecondsSinceEpoch}';

    return CompletedOrder(
      id: payload.ticketId ?? DateTime.parse(payload.timestamp).millisecondsSinceEpoch.toString(),
      orderNumber: orderNumber,
      items: items,
      logs: logs,
      total: payload.total,
      completedAt: DateTime.parse(payload.timestamp),
      clientName: payload.client?['name'] as String?,
      cashierName: 'Cajero ${payload.cashier ?? ""}',
      paymentMethod: paymentMethod,
      totalTax: totalTax,
      totalItems: totalItems,
      showSubtotalAndTax: false,
      showPricesWithTax: true,
    );
  }
}
