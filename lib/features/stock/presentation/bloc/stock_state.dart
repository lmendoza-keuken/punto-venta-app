import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/stock/domain/entities/stock_movement.dart';

abstract class StockState extends Equatable {
  const StockState();

  @override
  List<Object?> get props => [];
}

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockLoaded extends StockState {
  final List<Product> products;
  final Map<int, int> stockMap;

  const StockLoaded(this.products, this.stockMap);

  @override
  List<Object?> get props => [products, stockMap];
}

class StockOperationSuccess extends StockState {
  final String message;
  final List<Product> products;
  final Map<int, int> stockMap;

  const StockOperationSuccess(this.message, this.products, this.stockMap);

  @override
  List<Object?> get props => [message, products, stockMap];
}

class StockMovementsLoaded extends StockState {
  final List<StockMovement> movements;

  const StockMovementsLoaded(this.movements);

  @override
  List<Object?> get props => [movements];
}

class StockError extends StockState {
  final String message;

  const StockError(this.message);

  @override
  List<Object?> get props => [message];
}