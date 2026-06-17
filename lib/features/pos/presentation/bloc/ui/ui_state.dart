import 'package:equatable/equatable.dart';

abstract class UiState extends Equatable {
  const UiState();

  @override
  List<Object> get props => [];
}

class UiLoaded extends UiState {
  final int selectedQuantity;
  final bool isDeleteMode;
  final bool isBarcodeSearchEnabled;
  final bool isReturnMode;

  const UiLoaded({
    this.selectedQuantity = 1,
    this.isDeleteMode = false,
    this.isBarcodeSearchEnabled = true,
    this.isReturnMode = false,
  });

  UiLoaded copyWith({
    int? selectedQuantity,
    bool? isDeleteMode,
    bool? isBarcodeSearchEnabled,
    bool? isReturnMode,
  }) {
    return UiLoaded(
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
      isDeleteMode: isDeleteMode ?? this.isDeleteMode,
      isBarcodeSearchEnabled: isBarcodeSearchEnabled ?? this.isBarcodeSearchEnabled,
      isReturnMode: isReturnMode ?? this.isReturnMode,
    );
  }

  @override
  List<Object> get props => [
        selectedQuantity,
        isDeleteMode,
        isBarcodeSearchEnabled,
        isReturnMode,
      ];
}
