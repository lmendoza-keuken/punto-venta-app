import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/bootstrap_pvs_credentials_usecase.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

Future<void> bootstrapPvsCredentials() async {
  try {
    final enterprise = await di.sl<AuthLocalDataSource>().getCachedEnterprise();
    if (enterprise == null) return;
    await di.sl<BootstrapPvsCredentialsUsecase>()(enterprise.id);
  } catch (_) {
  }
}
