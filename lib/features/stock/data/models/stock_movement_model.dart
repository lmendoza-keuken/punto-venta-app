import 'package:punto_venta_app/features/stock/domain/entities/stock_movement.dart';

class StockMovementModel extends StockMovement {
  const StockMovementModel({
    required super.id,
    required super.productCodigo,
    required super.type,
    required super.quantity,
    required super.previousStock,
    required super.newStock,
    super.reason,
    required super.userId,
    required super.userName,
    required super.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'],
      productCodigo: json['productCodigo'],
      type: MovementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MovementType.ajuste,
      ),
      quantity: json['quantity'],
      previousStock: json['previousStock'],
      newStock: json['newStock'],
      reason: json['reason'],
      userId: json['userId'],
      userName: json['userName'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productCodigo': productCodigo,
      'type': type.name,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'reason': reason,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StockMovementModel.fromEntity(StockMovement movement) {
    return StockMovementModel(
      id: movement.id,
      productCodigo: movement.productCodigo,
      type: movement.type,
      quantity: movement.quantity,
      previousStock: movement.previousStock,
      newStock: movement.newStock,
      reason: movement.reason,
      userId: movement.userId,
      userName: movement.userName,
      createdAt: movement.createdAt,
    );
  }
}