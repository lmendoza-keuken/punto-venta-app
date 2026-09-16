import 'package:flutter_test/flutter_test.dart';
import 'package:punto_venta_app/features/app_update/domain/utils/update_availability.dart';

void main() {
  group('evaluateUpdateAvailability', () {
    test('no update when local build is current', () {
      final result = evaluateUpdateAvailability(
        localBuild: 12,
        remoteBuildNumber: 12,
        minSupportedBuildVersion: 1,
        mandatoryFlag: false,
      );
      expect(result.updateAvailable, isFalse);
      expect(result.forced, isFalse);
    });

    test('optional update when newer and above min supported', () {
      final result = evaluateUpdateAvailability(
        localBuild: 11,
        remoteBuildNumber: 12,
        minSupportedBuildVersion: 1,
        mandatoryFlag: false,
      );
      expect(result.updateAvailable, isTrue);
      expect(result.forced, isFalse);
    });

    test('forced when below minSupportedBuildVersion', () {
      final result = evaluateUpdateAvailability(
        localBuild: 11,
        remoteBuildNumber: 12,
        minSupportedBuildVersion: 12,
        mandatoryFlag: false,
      );
      expect(result.updateAvailable, isTrue);
      expect(result.forced, isTrue);
    });

    test('forced when mandatory flag is true', () {
      final result = evaluateUpdateAvailability(
        localBuild: 11,
        remoteBuildNumber: 12,
        minSupportedBuildVersion: 1,
        mandatoryFlag: true,
      );
      expect(result.updateAvailable, isTrue);
      expect(result.forced, isTrue);
    });

    test('no update when remote build is older', () {
      final result = evaluateUpdateAvailability(
        localBuild: 12,
        remoteBuildNumber: 10,
        minSupportedBuildVersion: 12,
        mandatoryFlag: true,
      );
      expect(result.updateAvailable, isFalse);
      expect(result.forced, isFalse);
    });
  });
}
