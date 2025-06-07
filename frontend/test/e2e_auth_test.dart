// End-to-end test to verify the complete authentication flow
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/api_service.dart';

void main() {
  group('End-to-End Authentication Tests', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    test('Test ApiService.login() directly - should return data with token and user', () async {
      // First register a test user
      final testEmail = 'e2e_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'password123';
      const testName = 'E2E Test User';

      debugPrint('🧪 Registering test user: $testEmail');
      
      try {
        final registerResponse = await apiService.register(testName, testEmail, testPassword);
        debugPrint('✅ Registration response: $registerResponse');
        
        // Verify registration response structure (should be already processed by ApiService._handleResponse)
        expect(registerResponse, isA<Map<String, dynamic>>());
        expect(registerResponse['token'], isNotNull);
        expect(registerResponse['user'], isNotNull);
        expect(registerResponse['user']['email'], equals(testEmail));
        
        debugPrint('✅ Registration successful - token and user data extracted correctly');
        
        // Now test login
        debugPrint('🧪 Testing login with same credentials');
        final loginResponse = await apiService.login(testEmail, testPassword);
        debugPrint('✅ Login response: $loginResponse');
        
        // Verify login response structure (should be already processed by ApiService._handleResponse)
        expect(loginResponse, isA<Map<String, dynamic>>());
        expect(loginResponse['token'], isNotNull);
        expect(loginResponse['user'], isNotNull);
        expect(loginResponse['user']['email'], equals(testEmail));
        
        debugPrint('✅ Login successful - token and user data extracted correctly');
        debugPrint('🎉 ApiService is working correctly with the backend!');
        
      } catch (e) {
        debugPrint('❌ Test failed with error: $e');
        fail('ApiService authentication failed: $e');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Test ApiService.login() with invalid credentials', () async {
      debugPrint('🧪 Testing login with invalid credentials');
      
      try {
        await apiService.login('invalid@example.com', 'wrongpassword');
        fail('Login should have failed with invalid credentials');
      } catch (e) {
        debugPrint('✅ Login correctly failed with invalid credentials: $e');
        // This is expected behavior
      }
    });
  });
}
