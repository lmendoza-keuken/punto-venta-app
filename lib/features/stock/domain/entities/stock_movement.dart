import 'package:equatable/equatable.dart';

enum MovementType {
  entrada, // Agregar stock
  salida, // Venta
  ajuste, // Corrección manual
  devolucion, // Devolución
}

class StockMovement extends Equatable {
  final String id;
  final int productCodigo; // Cambiado de productId a productCodigo
  final MovementType type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final String? reason;
  final String userId;
  final String userName;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.productCodigo,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.reason,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        productCodigo,
        type,
        quantity,
        previousStock,
        newStock,
        reason,
        userId,
        userName,
        createdAt,
      ];
}