import 'package:equatable/equatable.dart';

abstract class UiState extends Equatable {
  const UiState();

  @override
  List<Object> get props => [];
}

class UiLoaded extends UiState {
  final int selectedQuantity;
  final bool isDeleteMode;

  const UiLoaded({
    this.selectedQuantity = 1,
    this.isDeleteMode = false,
  });

  UiLoaded copyWith({
    int? selectedQuantity,
    bool? isDeleteMode,
  }) {
    return UiLoaded(
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
      isDeleteMode: isDeleteMode ?? this.isDeleteMode,
    );
  }

  @override
  List<Object> get props => [selectedQuantity, isDeleteMode];
}
