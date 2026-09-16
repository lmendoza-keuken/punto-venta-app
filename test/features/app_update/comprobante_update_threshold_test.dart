import 'package:flutter_test/flutter_test.dart';
import 'package:punto_venta_app/features/app_update/domain/utils/comprobante_update_threshold.dart';

void main() {
  group('shouldCheckUpdateForComprobantes', () {
    test('disabled when threshold is null or zero', () {
      expect(
        shouldCheckUpdateForComprobantes(
          countAfterIncrement: 10,
          threshold: null,
        ),
        isFalse,
      );
      expect(
        shouldCheckUpdateForComprobantes(
          countAfterIncrement: 10,
          threshold: 0,
        ),
        isFalse,
      );
    });

    test('triggers when count reaches threshold', () {
      expect(
        shouldCheckUpdateForComprobantes(
          countAfterIncrement: 49,
          threshold: 50,
        ),
        isFalse,
      );
      expect(
        shouldCheckUpdateForComprobantes(
          countAfterIncrement: 50,
          threshold: 50,
        ),
        isTrue,
      );
    });
  });
}
