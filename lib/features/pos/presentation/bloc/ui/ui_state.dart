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
  final bool isRefundMode;

  const UiLoaded({
    this.selectedQuantity = 1,
    this.isDeleteMode = false,
    this.isBarcodeSearchEnabled = true,
    this.isRefundMode = false,
  });

  UiLoaded copyWith({
    int? selectedQuantity,
    bool? isDeleteMode,
    bool? isBarcodeSearchEnabled,
    bool? isRefundMode,
  }) {
    return UiLoaded(
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
      isDeleteMode: isDeleteMode ?? this.isDeleteMode,
      isBarcodeSearchEnabled: isBarcodeSearchEnabled ?? this.isBarcodeSearchEnabled,
      isRefundMode: isRefundMode ?? this.isRefundMode,
    );
  }

  @override
  List<Object> get props => [
        selectedQuantity,
        isDeleteMode,
        isBarcodeSearchEnabled,
        isRefundMode,
      ];
}
