import 'customer_display_snapshot.dart';

/// Contrato para empujar la vista de cliente a una segunda ventana/display.
abstract class CustomerDisplayService {
  /// Windows o Android. En otras plataformas el toggle no se muestra.
  bool get isPlatformSupported;

  /// Hay un display secundario usable en este equipo.
  Future<bool> isAvailable();

  Future<void> start();

  Future<void> stop();

  Future<void> sync(CustomerDisplaySnapshot snapshot);

  /// Preferencia local de este equipo (SharedPreferences). Default: false.
  /// Si es true, la pantalla cliente se abre sola al iniciar.
  bool get isEnabled;

  Future<void> setEnabled(bool enabled);

  /// Emite después de [setEnabled] en esta sesión.
  Stream<bool> get enabledChanges;
}
