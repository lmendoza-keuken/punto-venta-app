import 'package:equatable/equatable.dart';

enum CartMode { sale, returnMode, disposeMode }

abstract class UiState extends Equatable {
  const UiState();

  @override
  List<Object> get props => [];
}

class UiLoaded extends UiState {
  final int selectedQuantity;
  final bool isDeleteMode;
  final bool isBarcodeSearchEnabled;
  final CartMode cartMode;
  final bool showConfirmationPanel;

  const UiLoaded({
    this.selectedQuantity = 1,
    this.isDeleteMode = false,
    this.isBarcodeSearchEnabled = true,
    this.cartMode = CartMode.sale,
    this.showConfirmationPanel = false,
  });

  bool get isReturnMode => cartMode == CartMode.returnMode;
  bool get isDisposeMode => cartMode == CartMode.disposeMode;
  bool get isSaleMode => cartMode == CartMode.sale;

  UiLoaded copyWith({
    int? selectedQuantity,
    bool? isDeleteMode,
    bool? isBarcodeSearchEnabled,
    CartMode? cartMode,
    bool? showConfirmationPanel,
  }) {
    return UiLoaded(
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
      isDeleteMode: isDeleteMode ?? this.isDeleteMode,
      isBarcodeSearchEnabled:
          isBarcodeSearchEnabled ?? this.isBarcodeSearchEnabled,
      cartMode: cartMode ?? this.cartMode,
      showConfirmationPanel:
          showConfirmationPanel ?? this.showConfirmationPanel,
    );
  }

  @override
  List<Object> get props => [
        selectedQuantity,
        isDeleteMode,
        isBarcodeSearchEnabled,
        cartMode,
        showConfirmationPanel,
      ];
}
