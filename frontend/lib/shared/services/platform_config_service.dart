// Platform-aware configuration service for API endpoints
// Handles different base URLs for different platforms (Android emulator, iOS, web, etc.)

import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformConfigService {
  static const String _defaultPort = '3000';
  
  /// Get the appropriate base URL for the current platform
  static String getBaseUrl() {
    // In web mode, use relative URLs or localhost
    if (kIsWeb) {
      return 'http://localhost:$_defaultPort/api';
    }
    
    // For mobile platforms
    if (Platform.isAndroid) {
      // Android emulator maps localhost to 10.0.2.2
      return 'http://10.0.2.2:$_defaultPort/api';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'http://localhost:$_defaultPort/api';
    } else {
      // Desktop platforms (Windows, macOS, Linux)
      return 'http://localhost:$_defaultPort/api';
    }
  }
  
  /// Get the base URL for image loading
  static String getImageBaseUrl() {
    // Similar logic but without /api suffix
    if (kIsWeb) {
      return 'http://localhost:$_defaultPort';
    }
    
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$_defaultPort';
    } else if (Platform.isIOS) {
      return 'http://localhost:$_defaultPort';
    } else {
      return 'http://localhost:$_defaultPort';
    }
  }
  
  /// Build complete image URL from filename
  static String? buildImageUrl(String? filename) {
    if (filename == null || filename.isEmpty) return null;
    
    final baseUrl = getImageBaseUrl();
    return '$baseUrl/uploads/$filename';
  }
  
  /// Get platform name for debugging
  static String getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
  
  /// Get current configuration info for debugging
  static Map<String, String> getConfigInfo() {
    return {
      'platform': getPlatformName(),
      'apiBaseUrl': getBaseUrl(),
      'imageBaseUrl': getImageBaseUrl(),
      'isWeb': kIsWeb.toString(),
      'isDebugMode': kDebugMode.toString(),
    };
  }
}
