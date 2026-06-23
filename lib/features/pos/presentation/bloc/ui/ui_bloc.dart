import 'package:flutter_bloc/flutter_bloc.dart';
import 'ui_event.dart';
import 'ui_state.dart';

class UiBloc extends Bloc<UiEvent, UiState> {
  UiBloc() : super(const UiLoaded()) {
    on<SetQuantity>(_onSetQuantity);
    on<ToggleDeleteMode>(_onToggleDeleteMode);
    on<ToggleBarcodeSearch>(_onToggleBarcodeSearch);
    on<ResetQuantity>(_onResetQuantity);
    on<ResetUiState>(_onResetUiState);
    on<ToggleReturnMode>(_onToggleReturnMode);
    on<OpenConfirmationPanel>(_onOpenConfirmationPanel);
    on<CloseConfirmationPanel>(_onCloseConfirmationPanel);
  }

  void _onSetQuantity(SetQuantity event, Emitter<UiState> emit) {
    if (state is UiLoaded) {
      final currentState = state as UiLoaded;
      emit(currentState.copyWith(selectedQuantity: event.quantity));
    }
  }

  void _onToggleDeleteMode(ToggleDeleteMode event, Emitter<UiState> emit) {
    if (state is UiLoaded) {
      final currentState = state as UiLoaded;
      emit(currentState.copyWith(isDeleteMode: !currentState.isDeleteMode));
    }
  }

  void _onToggleBarcodeSearch(ToggleBarcodeSearch event, Emitter<UiState> emit) {
    if (state is UiLoaded) {
      final currentState = state as UiLoaded;
      emit(currentState.copyWith(isBarcodeSearchEnabled: !currentState.isBarcodeSearchEnabled));
    }
  }

  void _onResetQuantity(ResetQuantity event, Emitter<UiState> emit) {
    if (state is UiLoaded) {
      final currentState = state as UiLoaded;
      emit(currentState.copyWith(selectedQuantity: 1));
    }
  }

  void _onResetUiState(ResetUiState event, Emitter<UiState> emit) {
    emit(const UiLoaded());
  }

  void _onToggleReturnMode(ToggleReturnMode event, Emitter<UiState> emit) {
    if (state is UiLoaded) {
      final currentState = state as UiLoaded;
      emit(currentState.copyWith(isReturnMode: !currentState.isReturnMode));
    }
  }

  void _onOpenConfirmationPanel(OpenConfirmationPanel event, Emitter<UiState> emit) {
    if (state is UiLoaded) {
      final currentState = state as UiLoaded;
      emit(currentState.copyWith(showConfirmationPanel: true));
    }
  }

  void _onCloseConfirmationPanel(CloseConfirmationPanel event, Emitter<UiState> emit) {
    if (state is UiLoaded) {
      final currentState = state as UiLoaded;
      emit(currentState.copyWith(showConfirmationPanel: false));
    }
  }
}
