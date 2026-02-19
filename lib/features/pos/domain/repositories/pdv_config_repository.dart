import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';

abstract class PdvConfigRepository {
  Future<PdvConfig> fetchPdvConfig();
  Future<PdvConfig?> getLocalPdvConfig();
  Future<void> savePdvConfig(PdvConfig config);
}
