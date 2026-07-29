import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vian_erp/main.dart';
import 'package:vian_erp/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Diagnose widget build exception', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'SOME_MOCK_TOKEN_WITHOUT_USER',
    });
    await ApiService.init();

    try {
      await tester.pumpWidget(const ProviderScope(child: VianERPApp()));
      // Pump initial route and redirect evaluation
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
    } catch (e, s) {
      print("CAUGHT WIDGET BUILD EXCEPTION: $e");
      print(s);
      rethrow;
    }
  });
}
