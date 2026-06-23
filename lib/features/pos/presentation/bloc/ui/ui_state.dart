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
  final bool showConfirmationPanel;

  const UiLoaded({
    this.selectedQuantity = 1,
    this.isDeleteMode = false,
    this.isBarcodeSearchEnabled = true,
    this.isReturnMode = false,
    this.showConfirmationPanel = false,
  });

  UiLoaded copyWith({
    int? selectedQuantity,
    bool? isDeleteMode,
    bool? isBarcodeSearchEnabled,
    bool? isReturnMode,
    bool? showConfirmationPanel,
  }) {
    return UiLoaded(
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
      isDeleteMode: isDeleteMode ?? this.isDeleteMode,
      isBarcodeSearchEnabled: isBarcodeSearchEnabled ?? this.isBarcodeSearchEnabled,
      isReturnMode: isReturnMode ?? this.isReturnMode,
      showConfirmationPanel: showConfirmationPanel ?? this.showConfirmationPanel,
    );
  }

  @override
  List<Object> get props => [
        selectedQuantity,
        isDeleteMode,
        isBarcodeSearchEnabled,
        isReturnMode,
        showConfirmationPanel,
      ];
}
