// Simple Logger Service for the Application
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class AppLogger {
  static const String _tag = 'GestaoEstoque';
  
  static void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }
  
  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }
  
  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }
  
  static void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, tag);
    if (error != null) {
      _log(LogLevel.error, 'Error details: $error', tag);
    }
    if (stackTrace != null && kDebugMode) {
      _log(LogLevel.error, 'Stack trace: $stackTrace', tag);
    }
  }
  
  static void _log(LogLevel level, String message, String? tag) {
    if (kDebugMode) {
      final String formattedTag = tag ?? _tag;
      final String levelStr = level.name.toUpperCase();
      final String timestamp = DateTime.now().toIso8601String();
      
      // Use debugPrint in debug mode for better performance and filtering
      debugPrint('[$timestamp] [$levelStr] [$formattedTag] $message');
    }
    // In release mode, only log errors to system log
    else if (level == LogLevel.error) {
      debugPrint('[ERROR] [$_tag] $message');
    }
  }
}
