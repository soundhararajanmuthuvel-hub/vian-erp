import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static const String productionBaseUrl = 'https://vian-erp-production.up.railway.app/api';
  static const String localBaseUrl = 'http://localhost:5050/api';
  
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl.endsWith('/api') ? envUrl : '$envUrl/api';
    }
    
    if (kIsWeb) {
      final base = Uri.base;
      if (base.host == 'localhost' || base.host == '127.0.0.1') {
        return localBaseUrl;
      }
    }
    return productionBaseUrl;
  }

  static const Duration timeout = Duration(seconds: 15);
  
  static Map<String, String> getHeaders(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
