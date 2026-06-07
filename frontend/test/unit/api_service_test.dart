import 'package:flutter_test/flutter_test.dart';
import 'package:renthub/services/api_service.dart';

void main() {
  group('ApiService.buildUrl', () {
    test('TC-UI-001 menggabungkan baseUrl dan path', () {
      final url = ApiService.buildUrl('/bookings/estimate');
      expect(url, contains('/api/bookings/estimate'));
    });

    test('TC-UI-006 buildUrl dengan path tanpa slash depan', () {
      final url = ApiService.buildUrl('auth/login');
      expect(url, contains('/api/auth/login'));
    });
  });
}
