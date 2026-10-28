import 'customer_display_snapshot.dart';

/// Contrato para empujar la vista de cliente a una segunda ventana/display.
abstract class CustomerDisplayService {
  /// Windows: siempre true (puede abrir 2 ventanas en 1 monitor).
  /// Android: true solo si hay display secundario Presentation.
  Future<bool> isAvailable();

  Future<void> start();

  Future<void> stop();

  Future<void> sync(CustomerDisplaySnapshot snapshot);

  /// Preferencia de usuario (SharedPreferences). Default: true.
  bool get isEnabled;

  Future<void> setEnabled(bool enabled);
}
