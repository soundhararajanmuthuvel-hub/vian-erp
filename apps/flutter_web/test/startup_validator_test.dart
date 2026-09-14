import 'package:flutter_test/flutter_test.dart';
import 'package:vian_erp/core/widgets/error_recovery.dart';

void main() {
  group('VianStartupValidator Health URL Normalization', () {
    test('Normalizes base URL with trailing slash', () {
      final uri = VianStartupValidator.getHealthUri('https://vian-erp-api.onrender.com/api/');
      expect(uri.toString(), equals('https://vian-erp-api.onrender.com/api/health'));
    });

    test('Normalizes base URL without trailing slash', () {
      final uri = VianStartupValidator.getHealthUri('https://vian-erp-api.onrender.com/api');
      expect(uri.toString(), equals('https://vian-erp-api.onrender.com/api/health'));
    });

    test('Does not duplicate /health if already present', () {
      final uri = VianStartupValidator.getHealthUri('https://vian-erp-api.onrender.com/api/health');
      expect(uri.toString(), equals('https://vian-erp-api.onrender.com/api/health'));
    });

    test('Trims whitespace and redundant trailing slashes', () {
      final uri = VianStartupValidator.getHealthUri('  https://vian-erp-api.onrender.com/api///  ');
      expect(uri.toString(), equals('https://vian-erp-api.onrender.com/api/health'));
    });
  });
}
