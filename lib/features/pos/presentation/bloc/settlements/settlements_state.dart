import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_canceled_items_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_collectors_detail_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_collectors_response_model.dart';

abstract class SettlementsState extends Equatable {
  const SettlementsState();

  @override
  List<Object> get props => [];
}

class SettlementsInitial extends SettlementsState {}

class SettlementsLoading extends SettlementsState {}

class SettlementsLoaded extends SettlementsState {
  final List<PendingCollectorsResponseModel> pendingCollectors;

  const SettlementsLoaded(this.pendingCollectors);

  @override
  List<Object> get props => [pendingCollectors];
}

class PendingCollectorsDetailLoaded extends SettlementsState {
  final PendingCollectorsDetailResponseModel pendingCollectorsDetail;

  const PendingCollectorsDetailLoaded(this.pendingCollectorsDetail);

  @override
  List<Object> get props => [pendingCollectorsDetail];
}

class PendingCanceledItemsLoaded extends SettlementsState {
  final List<PendingCanceledTicketModel> canceledTickets;

  const PendingCanceledItemsLoaded(this.canceledTickets);

  @override
  List<Object> get props => [canceledTickets];
}

class SettlementsError extends SettlementsState {
  final String message;

  const SettlementsError(this.message);

  @override
  List<Object> get props => [message];
}
