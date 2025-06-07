// Simple Flutter test to verify authentication after AuthProvider fix
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/providers/auth_provider.dart';

void main() {
  group('Authentication Flow Tests', () {
    late ApiService apiService;
    late AuthProvider authProvider;

    setUp(() {
      apiService = ApiService();
      authProvider = AuthProvider(apiService);
    });

    test('Test login with correct credentials', () async {      // Test with a user that should exist or create one for testing
      const email = 'test@example.com';
      const password = 'password123';
      
      try {
        // First try to register the user (might fail if already exists, that's ok)
        await authProvider.register('Test User', email, password);
      } catch (e) {
        // User might already exist, continue with login test
        debugPrint('Registration failed (user might already exist): $e');
      }
      
      // Test login
      final loginSuccess = await authProvider.login(email, password);
      
      expect(loginSuccess, true, reason: 'Login should succeed with correct credentials');
      expect(authProvider.isAuthenticated, true, reason: 'User should be authenticated after successful login');
      expect(authProvider.token, isNotNull, reason: 'Token should be set after login');
      expect(authProvider.user, isNotNull, reason: 'User should be set after login');
      
      debugPrint('✅ Login test passed!');
      debugPrint('Token: ${authProvider.token}');
      debugPrint('User: ${authProvider.user?.name} (${authProvider.user?.email})');
    });

    test('Test login with incorrect credentials', () async {
      final loginSuccess = await authProvider.login('nonexistent@example.com', 'wrongpassword');
      
      expect(loginSuccess, false, reason: 'Login should fail with incorrect credentials');
      expect(authProvider.isAuthenticated, false, reason: 'User should not be authenticated after failed login');
      expect(authProvider.token, isNull, reason: 'Token should be null after failed login');
      expect(authProvider.user, isNull, reason: 'User should be null after failed login');
      
      debugPrint('✅ Invalid login test passed!');
    });

    test('Test token persistence', () async {      // Login first
      const email = 'test@example.com';
      const password = 'password123';
      
      final loginSuccess = await authProvider.login(email, password);
      expect(loginSuccess, true);
      
      final originalToken = authProvider.token;
      final originalUser = authProvider.user;
      
      // Create a new AuthProvider instance to simulate app restart
      final newAuthProvider = AuthProvider(apiService);
      
      // Wait a bit for the stored auth to load
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(newAuthProvider.token, equals(originalToken), reason: 'Token should persist across app restarts');
      expect(newAuthProvider.user?.id, equals(originalUser?.id), reason: 'User should persist across app restarts');
      expect(newAuthProvider.isAuthenticated, true, reason: 'Authentication state should persist');
      
      debugPrint('✅ Token persistence test passed!');
    });
  });
}
