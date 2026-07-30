import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vian_erp/main.dart';
import 'package:vian_erp/user_management.dart';
import 'package:vian_erp/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    ApiService.useMockData = true;
  });

  testWidgets('Diagnose cold start (not logged in)', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.init();

    try {
      await tester.pumpWidget(const ProviderScope(child: VianERPApp()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    } catch (e, s) {
      print("CAUGHT COLD START EXCEPTION: $e");
      print(s);
      rethrow;
    }
  });

  testWidgets('Diagnose UserManagementTab Users List', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'MOCK_JWT_TOKEN_SUPER_ADMIN',
      'current_user': '{"id":99,"employeeId":"VIAN-MOCK-99","username":"superadmin","name":"Ar. Anand Sathiesivam","email":"superadmin@vianarchitects.com","role":"Super Admin","department":"Executive","designation":"Managing Director"}',
    });
    await ApiService.init();

    try {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: UserManagementTab()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    } catch (e, s) {
      print("CAUGHT USERS LIST EXCEPTION: $e");
      print(s);
      rethrow;
    }
  });

  testWidgets('Diagnose UserManagementTab Create Dialog', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'MOCK_JWT_TOKEN_SUPER_ADMIN',
      'current_user': '{"id":99,"employeeId":"VIAN-MOCK-99","username":"superadmin","name":"Ar. Anand Sathiesivam","email":"superadmin@vianarchitects.com","role":"Super Admin","department":"Executive","designation":"Managing Director"}',
    });
    await ApiService.init();

    try {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: UserManagementTab(showCreateDialog: true)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    } catch (e, s) {
      print("CAUGHT CREATE DIALOG EXCEPTION: $e");
      print(s);
      rethrow;
    }
  });

  testWidgets('Diagnose logged in as Managing Director', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'MOCK_JWT_TOKEN_MANAGING_DIRECTOR',
      'current_user': '{"id":98,"employeeId":"VIAN-MOCK-98","username":"md","name":"Ar. Vijay Vinthan","email":"md@demo.vianerp.test","role":"Managing Director","department":"Executive","designation":"Managing Director"}',
    });
    await ApiService.init();
    try {
      await tester.pumpWidget(const ProviderScope(child: VianERPApp()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    } catch (e, s) {
      print("CAUGHT MD EXCEPTION: $e");
      print(s);
      rethrow;
    }
  });

  testWidgets('Diagnose logged in as Admin', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'MOCK_JWT_TOKEN_ADMIN',
      'current_user': '{"id":97,"employeeId":"VIAN-MOCK-97","username":"admin","name":"Jaya","email":"admin@demo.vianerp.test","role":"Admin / Office Manager / Accounts","department":"Administration","designation":"Office Manager / Accountant"}',
    });
    await ApiService.init();
    try {
      await tester.pumpWidget(const ProviderScope(child: VianERPApp()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    } catch (e, s) {
      print("CAUGHT ADMIN EXCEPTION: $e");
      print(s);
      rethrow;
    }
  });

  testWidgets('Diagnose logged in as Project Manager', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'MOCK_JWT_TOKEN_PM',
      'current_user': '{"id":96,"employeeId":"VIAN-MOCK-96","username":"pm","name":"Er. Rajesh","email":"pm@demo.vianerp.test","role":"Project Manager","department":"Site Team","designation":"Senior Project Manager"}',
    });
    await ApiService.init();
    try {
      await tester.pumpWidget(const ProviderScope(child: VianERPApp()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    } catch (e, s) {
      print("CAUGHT PM EXCEPTION: $e");
      print(s);
      rethrow;
    }
  });

  testWidgets('Diagnose logged in as Architect', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'MOCK_JWT_TOKEN_ARCHITECT',
      'current_user': '{"id":95,"employeeId":"VIAN-MOCK-95","username":"architect","name":"Muthuiya","email":"architect@demo.vianerp.test","role":"Tech Head + Senior Architect","department":"Designing Team","designation":"Senior Architect / Tech Head"}',
    });
    await ApiService.init();
    try {
      await tester.pumpWidget(const ProviderScope(child: VianERPApp()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    } catch (e, s) {
      print("CAUGHT ARCHITECT EXCEPTION: $e");
      print(s);
      rethrow;
    }
  });

  testWidgets('Diagnose logged in as Site Engineer', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'MOCK_JWT_TOKEN_SITE_ENGINEER',
      'current_user': '{"id":94,"employeeId":"VIAN-MOCK-94","username":"siteengineer","name":"Er. Anthony","email":"siteengineer@demo.vianerp.test","role":"Site Engineer","department":"Site Team","designation":"Site Execution Engineer"}',
    });
    await ApiService.init();
    try {
      await tester.pumpWidget(const ProviderScope(child: VianERPApp()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    } catch (e, s) {
      print("CAUGHT SITE ENGINEER EXCEPTION: $e");
      print(s);
      rethrow;
    }
  });

  testWidgets('Diagnose logged in as Accountant', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'MOCK_JWT_TOKEN_ACCOUNTANT',
      'current_user': '{"id":93,"employeeId":"VIAN-MOCK-93","username":"accountant","name":"Er. Suresh","email":"accountant@demo.vianerp.test","role":"Accountant","department":"Administration","designation":"Accountant"}',
    });
    await ApiService.init();
    try {
      await tester.pumpWidget(const ProviderScope(child: VianERPApp()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    } catch (e, s) {
      print("CAUGHT ACCOUNTANT EXCEPTION: $e");
      print(s);
      rethrow;
    }
  });

  testWidgets('Diagnose logged in as Client', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'MOCK_JWT_TOKEN_CLIENT',
      'current_user': '{"id":92,"employeeId":"VIAN-MOCK-92","username":"client","name":"Bajaj Villa Client","email":"client@demo.vianerp.test","role":"Client","department":"External","designation":"Property Owner"}',
    });
    await ApiService.init();
    try {
      await tester.pumpWidget(const ProviderScope(child: VianERPApp()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    } catch (e, s) {
      print("CAUGHT CLIENT EXCEPTION: $e");
      print(s);
      rethrow;
    }
  });
}
