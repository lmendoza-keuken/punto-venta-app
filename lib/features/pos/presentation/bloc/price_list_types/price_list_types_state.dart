import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/data/models/price_list_type_response_model.dart';

abstract class PriceListTypesState extends Equatable {
  const PriceListTypesState();
  @override
  List<Object?> get props => [];
}

class PriceListTypesInitial extends PriceListTypesState {}

class PriceListTypesLoading extends PriceListTypesState {}

class PriceListTypesLoaded extends PriceListTypesState   {
  final List<PriceListTypeResponseModel> listTypes;

  const PriceListTypesLoaded({this.listTypes = const []});

  @override
  List<Object?> get props => [listTypes];
}

class PriceListTypesError extends PriceListTypesState {
  final String message;

  const PriceListTypesError(this.message);

  @override
  List<Object?> get props => [message];
}

