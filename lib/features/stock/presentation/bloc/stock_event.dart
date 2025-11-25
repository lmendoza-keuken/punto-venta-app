import 'package:equatable/equatable.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends StockEvent {}

class AddStock extends StockEvent {
  final int productCodigo;
  final int quantity;
  final String reason;

  const AddStock({
    required this.productCodigo,
    required this.quantity,
    required this.reason,
  });

  @override
  List<Object?> get props => [productCodigo, quantity, reason];
}

class RemoveStock extends StockEvent {
  final int productCodigo;
  final int quantity;
  final String reason;

  const RemoveStock({
    required this.productCodigo,
    required this.quantity,
    required this.reason,
  });

  @override
  List<Object?> get props => [productCodigo, quantity, reason];
}

class AdjustStock extends StockEvent {
  final int productCodigo;
  final int newStock;
  final String reason;

  const AdjustStock({
    required this.productCodigo,
    required this.newStock,
    required this.reason,
  });

  @override
  List<Object?> get props => [productCodigo, newStock, reason];
}

class LoadMovements extends StockEvent {
  final int? productCodigo;
  final DateTime? fromDate;
  final DateTime? toDate;

  const LoadMovements({
    this.productCodigo,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [productCodigo, fromDate, toDate];
}