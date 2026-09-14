import 'package:flutter_test/flutter_test.dart';
import 'package:vian_erp/core/services/demo_credentials.dart';

void main() {
  group('DemoAccountService Tests', () {
    test('Service has exactly 9 roles defined', () {
      expect(DemoAccountService.accounts.length, 9);

      final roles = DemoAccountService.accounts.map((a) => a.role).toList();
      expect(
        roles,
        containsAll([
          DemoRole.superAdmin,
          DemoRole.managingDirector,
          DemoRole.admin,
          DemoRole.projectManager,
          DemoRole.architect,
          DemoRole.siteEngineer,
          DemoRole.accountant,
          DemoRole.client,
          DemoRole.developer,
        ]),
      );
    });

    test('shouldShow returns credentials when enabled in dev mode', () {
      final show = DemoAccountService.shouldShow;
      if (show) {
        expect(
          DemoAccountService.getCredentialsInternal(DemoRole.superAdmin),
          isNotNull,
        );
        expect(
          DemoAccountService.getCredentialsInternal(
            DemoRole.superAdmin,
          )!['email'],
          'superadmin@vianarchitects.com',
        );
      } else {
        expect(
          DemoAccountService.getCredentialsInternal(DemoRole.superAdmin),
          isNull,
        );
      }
    });
  });
}
