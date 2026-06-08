import 'package:flutter_bloc/flutter_bloc.dart';
import 'ui_event.dart';
import 'ui_state.dart';

class UiBloc extends Bloc<UiEvent, UiState> {
  UiBloc() : super(const UiLoaded()) {
    on<SetQuantity>(_onSetQuantity);
    on<ToggleDeleteMode>(_onToggleDeleteMode);
    on<ToggleBarcodeSearch>(_onToggleBarcodeSearch);
    on<ToggleRefundMode>(_onToggleRefundMode);
    on<ResetQuantity>(_onResetQuantity);
    on<ResetUiState>(_onResetUiState);
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

  void _onToggleRefundMode(ToggleRefundMode event, Emitter<UiState> emit) {
    if (state is UiLoaded) {
      final currentState = state as UiLoaded;
      emit(currentState.copyWith(isRefundMode: !currentState.isRefundMode));
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
}
