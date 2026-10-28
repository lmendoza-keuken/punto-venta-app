import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_prefs.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_service.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoOpCustomerDisplayService implements CustomerDisplayService {
  NoOpCustomerDisplayService(this._prefs);

  final SharedPreferences _prefs;

  @override
  bool get isEnabled =>
      _prefs.getBool(CustomerDisplayPrefs.enabledKey) ?? true;

  @override
  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(CustomerDisplayPrefs.enabledKey, enabled);
  }

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> start() async {
    AppLogger.info('CustomerDisplay NoOp: start ignorado');
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> sync(CustomerDisplaySnapshot snapshot) async {}
}
