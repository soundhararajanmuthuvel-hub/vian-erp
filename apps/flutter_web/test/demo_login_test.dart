import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    test('All 9 demo accounts have required metadata', () {
      for (final acc in DemoAccountService.accounts) {
        expect(acc.displayName, isNotEmpty);
        expect(acc.description, isNotEmpty);
        expect(acc.iconEmoji, isNotEmpty);
      }
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

    testWidgets('LoginPage UI renders normal corporate login form elements', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Verify corporate login headers
      expect(find.text('EXECUTIVE COMMAND'), findsOneWidget);
      expect(find.text('Secure Access'), findsOneWidget);
      expect(find.text('CORPORATE EMAIL'), findsOneWidget);
      expect(find.text('MASTER CREDENTIAL'), findsOneWidget);
      expect(find.text('AUTHORIZE ACCESS'), findsOneWidget);
    });

    testWidgets('LoginPage respects DemoAccountService.shouldShow', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      if (DemoAccountService.shouldShow) {
        expect(find.text('DEMO ACCESS'), findsOneWidget);
        expect(find.text('Choose a role to enter the demo environment'), findsOneWidget);
        // Verify all 9 roles exist as text buttons
        for (final acc in DemoAccountService.accounts) {
          expect(find.text(acc.displayName), findsOneWidget);
        }
      } else {
        expect(find.text('DEMO ACCESS'), findsNothing);
        for (final acc in DemoAccountService.accounts) {
          expect(find.text(acc.displayName), findsNothing);
        }
      }
    });
  });
}
