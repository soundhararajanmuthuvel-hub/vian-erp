import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vian_erp/core/services/api_constants.dart';
import 'package:vian_erp/core/services/demo_credentials.dart';
import 'package:vian_erp/main.dart';

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

    test('All 9 demo credentials map to correct emails and non-empty passwords', () {
      for (final acc in DemoAccountService.accounts) {
        final creds = DemoAccountService.getCredentialsInternal(acc.role);
        if (DemoAccountService.shouldShow) {
          expect(creds, isNotNull);
          expect(creds!['email'], isNotEmpty);
          expect(creds['password'], isNotEmpty);
          expect(creds['username'], isNotEmpty);
        }
      }
    });
  });

  group('Login Routing & UI Regression Tests', () {
    test('ApiConstants productionBaseUrl is https://vian-erp-api.onrender.com/api', () {
      expect(
        ApiConstants.productionBaseUrl,
        'https://vian-erp-api.onrender.com/api',
      );
    });

    test('GoRouter contains /login mapping to LoginPage', () {
      final routes = vianRouter.configuration.routes;
      final loginRoute = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/login',
      );
      expect(loginRoute, isNotNull);
      expect(loginRoute.path, '/login');
    });
  });
}
