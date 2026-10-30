import 'package:punto_venta_app/features/pos/data/models/mercado_pago/pvs_credentials_model.dart';

// =============================================================================
// TEMP MOCK — PVS testing. Un solo switch para todo.
// =============================================================================

/// Master switch: credenciales mock + botón simular pago homo.
const bool kPvsQrMockEnabled = true;

const String kPvsMockClientId = 'ext-133';
const String kPvsMockClientSecret = '2b50df0e-16ab-40fa-95ba-5813dc66f980';

PvsCredentials kPvsMockCredentialsFor(int paymentMethodId) => PvsCredentials(
      paymentMethodId: paymentMethodId,
      clientId: kPvsMockClientId,
      clientSecret: kPvsMockClientSecret,
    );
