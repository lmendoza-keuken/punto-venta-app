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

class ResetQuantity extends UiEvent {}

class ResetUiState extends UiEvent {}

class ToggleReturnMode extends UiEvent {}

class OpenConfirmationPanel extends UiEvent {}

class CloseConfirmationPanel extends UiEvent {}

/// Bloquea el catálogo / lado izquierdo mientras el cobro QR está en pantalla.
class SetMpQrActive extends UiEvent {
  final bool isActive;

  const SetMpQrActive(this.isActive);

  @override
  List<Object> get props => [isActive];
}
