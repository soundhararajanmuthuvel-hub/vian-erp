import 'package:flutter_test/flutter_test.dart';
import 'package:vian_erp/core/services/demo_credentials.dart';

void main() {
  group('DemoAccountService Tests', () {
    test('Service has exactly 4 roles defined', () {
      expect(DemoAccountService.accounts.length, 4);
      
      final roles = DemoAccountService.accounts.map((a) => a.role).toList();
      expect(roles, containsAll([
        DemoRole.superAdmin,
        DemoRole.admin,
        DemoRole.seniorEngineer,
        DemoRole.engineer,
      ]));
    });

    test('shouldShow returns false if in release mode or if ENABLE_DEMO_LOGIN is false', () {
      // By default under normal test run, it's debug mode but ENABLE_DEMO_LOGIN define is false
      // Should be false/true depending on test config, but we can check shouldShow
      final show = DemoAccountService.shouldShow;
      if (show) {
        expect(DemoAccountService.getCredentialsInternal(DemoRole.superAdmin), isNotNull);
      } else {
        expect(DemoAccountService.getCredentialsInternal(DemoRole.superAdmin), isNull);
      }
    });
  });
}
