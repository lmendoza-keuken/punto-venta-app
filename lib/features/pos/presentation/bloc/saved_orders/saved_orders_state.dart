import 'package:equatable/equatable.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/saved_order.dart';

abstract class SavedOrdersState extends Equatable {
  const SavedOrdersState();

  @override
  List<Object> get props => [];
}

class SavedOrdersInitial extends SavedOrdersState {}

class SavedOrdersLoading extends SavedOrdersState {}

class SavedOrdersLoaded extends SavedOrdersState {
  final List<SavedOrder> orders;

  const SavedOrdersLoaded(this.orders);

  @override
  List<Object> get props => [orders];
}

class SavedOrdersError extends SavedOrdersState {
  final String message;

  const SavedOrdersError(this.message);

  @override
  List<Object> get props => [message];
}

class OrderSaved extends SavedOrdersState {
  final String message;

  const OrderSaved(this.message);

  @override
  List<Object> get props => [message];
}

class OrderDeleted extends SavedOrdersState {
  final String message;

  const OrderDeleted(this.message);

  @override
  List<Object> get props => [message];
}

class OrderLoadedById extends SavedOrdersState {
  final SavedOrder order;

  const OrderLoadedById(this.order);

  @override
  List<Object> get props => [order];
}
