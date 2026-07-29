import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vian_erp/core/services/demo_credentials.dart';
import 'package:vian_erp/core/services/demo_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DemoAccountService Tests', () {
    test('Service has exactly 8 roles defined', () {
      expect(DemoAccountService.accounts.length, 8);
      
      final roles = DemoAccountService.accounts.map((a) => a.role).toList();
      expect(roles, containsAll([
        DemoRole.superAdmin,
        DemoRole.managingDirector,
        DemoRole.admin,
        DemoRole.projectManager,
        DemoRole.architect,
        DemoRole.siteEngineer,
        DemoRole.accountant,
        DemoRole.client,
      ]));
    });

    test('shouldShow returns credentials when enabled in dev mode', () {
      final show = DemoAccountService.shouldShow;
      if (show) {
        final creds = DemoAccountService.getCredentialsInternal(DemoRole.superAdmin);
        expect(creds, isNotNull);
        expect(creds!['email'], 'superadmin@vianarchitects.com');
        expect(creds['username'], 'superadmin');
      } else {
        expect(DemoAccountService.getCredentialsInternal(DemoRole.superAdmin), isNull);
      }
    });

    test('DemoAuthService.login succeeds for all 8 roles in dev mode', () async {
      if (DemoAccountService.shouldShow) {
        for (final account in DemoAccountService.accounts) {
          final res = await DemoAuthService.login(account.role);
          expect(res['success'], isTrue, reason: 'Failed to authenticate role ${account.displayName}');
          expect(res['user'], isNotNull);
        }
      }
    });
  });
}
