import 'package:equatable/equatable.dart';

abstract class UiEvent extends Equatable {
  const UiEvent();

  @override
  List<Object> get props => [];
}

class SetQuantity extends UiEvent {
  final int quantity;

  const SetQuantity(this.quantity);

  @override
  List<Object> get props => [quantity];
}

class ToggleDeleteMode extends UiEvent {}

class ToggleBarcodeSearch extends UiEvent {}

class ToggleRefundMode extends UiEvent {}

class ResetQuantity extends UiEvent {}

class ResetUiState extends UiEvent {}
