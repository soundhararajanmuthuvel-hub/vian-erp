import 'api_service.dart';
import 'demo_credentials.dart';

class DemoAuthService {
  static Future<Map<String, dynamic>> login(DemoRole role) async {
    if (!DemoAccountService.shouldShow) {
      return {'success': false, 'message': 'Demo login disabled in this environment'};
    }

    final creds = DemoAccountService.getCredentialsInternal(role);
    if (creds == null) {
      return {'success': false, 'message': 'Credentials not found'};
    }

    final email = creds['email']!;
    final password = creds['password']!;

    final res = await ApiService.login(email, password);
    if (res['success'] == true) {
      final user = Map<String, dynamic>.from(res['user'] ?? {});
      user['isDemoSession'] = true;
      user['isDemo'] = true;
      
      return {
        'success': true,
        'user': user,
      };
    }
    return res;
  }
}
