import 'package:equatable/equatable.dart';

abstract class PriceListTypesEvent extends Equatable {
  const PriceListTypesEvent();
  @override
  List<Object?> get props => [];
}

class FetchPriceListTypesEvent extends PriceListTypesEvent {}

