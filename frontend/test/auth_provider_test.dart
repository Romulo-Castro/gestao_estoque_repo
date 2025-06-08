// test/auth_provider_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/data/datasources/api_service.dart';
import 'package:frontend/core/presentation/providers/auth_provider.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
  });

  group('AuthProvider Tests', () {
    late ApiService apiService;
    late AuthProvider authProvider;

    setUp(() {
      apiService = ApiService();
      authProvider = AuthProvider(apiService);
    });

    test('initial state should be unauthenticated', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, isNull);
      expect(authProvider.user, isNull);
    });

    test('logout should clear authentication state', () {
      authProvider.logout();
      
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, isNull);
      expect(authProvider.user, isNull);
    });

    test('loading state should be false initially', () {
      expect(authProvider.isLoading, false);
    });

    test('should handle initialization correctly', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, isNull);
      expect(authProvider.user, isNull);
      expect(authProvider.isLoading, false);
    });
  });
}
