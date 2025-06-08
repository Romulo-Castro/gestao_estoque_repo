// lib/shared/config/app_config.dart
class AppConfig {
  // API Configuration
  static const String baseUrl = 'http://localhost:3000';
  static const String apiPath = '/api';
  
  // Complete API base URL
  static String get apiBaseUrl => '$baseUrl$apiPath';
  
  // Request timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // App Constants
  static const String appName = 'Gestão de Estoque';
  static const String appVersion = '1.0.0';
  
  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedImportTypes = ['csv', 'xlsx'];
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Authentication
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  
  // Environment-specific configs
  static bool get isDebug {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
  
  static bool get isProduction => !isDebug;
}
