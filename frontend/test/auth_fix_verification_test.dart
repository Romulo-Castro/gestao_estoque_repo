import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/api_service.dart';

void main() {
  group('AuthProvider Fix Verification', () {
    test('Verify AuthProvider handles ApiService response correctly', () async {
      // This test verifies that AuthProvider can handle the response structure
      // that ApiService._handleResponse() returns after extracting data from backend
      
      final apiService = ApiService();
      final authProvider = AuthProvider(apiService);
      
      // Create a test user
      final testEmail = 'auth_fix_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'password123';
      const testName = 'Auth Fix Test User';

      print('🧪 Testing AuthProvider.register()...');
      
      try {
        final registerSuccess = await authProvider.register(testName, testEmail, testPassword);
        
        expect(registerSuccess, true, reason: 'Registration should succeed');
        expect(authProvider.isAuthenticated, true, reason: 'Should be authenticated after registration');
        expect(authProvider.token, isNotNull, reason: 'Token should be set');
        expect(authProvider.user, isNotNull, reason: 'User should be set');
        expect(authProvider.user!.email, equals(testEmail), reason: 'User email should match');
        
        print('✅ Registration works correctly!');
        
        // Logout to test login separately
        await authProvider.logout();
        expect(authProvider.isAuthenticated, false, reason: 'Should not be authenticated after logout');
        
        print('🧪 Testing AuthProvider.login()...');
        
        // Test login
        final loginSuccess = await authProvider.login(testEmail, testPassword);
        
        expect(loginSuccess, true, reason: 'Login should succeed');
        expect(authProvider.isAuthenticated, true, reason: 'Should be authenticated after login');
        expect(authProvider.token, isNotNull, reason: 'Token should be set after login');
        expect(authProvider.user, isNotNull, reason: 'User should be set after login');
        expect(authProvider.user!.email, equals(testEmail), reason: 'User email should match after login');
        
        print('✅ Login works correctly!');
        print('🎉 AuthProvider fix verified - no more "Resposta inválida do servidor" error!');
        
      } catch (e) {
        print('❌ Test failed: $e');
        fail('AuthProvider test failed: $e');
      }
    });
    
    test('Verify error handling for invalid credentials', () async {
      final apiService = ApiService();
      final authProvider = AuthProvider(apiService);
      
      print('🧪 Testing AuthProvider with invalid credentials...');
      
      final loginSuccess = await authProvider.login('invalid@example.com', 'wrongpassword');
      
      expect(loginSuccess, false, reason: 'Login should fail with invalid credentials');
      expect(authProvider.isAuthenticated, false, reason: 'Should not be authenticated after failed login');
      expect(authProvider.token, isNull, reason: 'Token should be null after failed login');
      expect(authProvider.user, isNull, reason: 'User should be null after failed login');
      expect(authProvider.error, isNotNull, reason: 'Error should be set after failed login');
      
      print('✅ Error handling works correctly!');
      print('Error message: ${authProvider.error}');
    });
  });
}
