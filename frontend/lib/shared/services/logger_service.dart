import 'package:flutter/foundation.dart';

/// Log levels for different types of messages
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// A comprehensive logging service for the application
/// Provides different log levels and conditional logging based on build mode
class LoggerService {
  static const String _tag = 'InventoryApp';
  
  /// Logs a debug message (only in debug mode)
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Logs an info message
  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Logs a warning message
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Logs an error message
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Internal logging method
  static void _log(LogLevel level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    // Only log debug messages in debug mode
    if (level == LogLevel.debug && !kDebugMode) {
      return;
    }
    
    final String logTag = tag ?? _tag;
    final String levelStr = level.name.toUpperCase();
    final String timestamp = DateTime.now().toIso8601String();
    
    String logMessage = '[$timestamp] [$levelStr] [$logTag] $message';
    
    if (error != null) {
      logMessage += '\nError: $error';
    }
    
    if (stackTrace != null) {
      logMessage += '\nStackTrace: $stackTrace';
    }
    
    // In debug mode, use debugPrint for better console output
    if (kDebugMode) {
      debugPrint(logMessage);
    } else {      // In release mode, you might want to send logs to a service
      // For now, we'll still print to console but this could be replaced
      // with a service like Firebase Crashlytics, Sentry, etc.
      // Debug: $logMessage
    }
  }
  
  /// Logs API requests for debugging
  static void apiRequest(String method, String url, {Map<String, dynamic>? body}) {
    if (kDebugMode) {
      debug('API Request: $method $url${body != null ? '\nBody: $body' : ''}', tag: 'API');
    }
  }
  
  /// Logs API responses for debugging
  static void apiResponse(String url, int statusCode, {dynamic body}) {
    if (kDebugMode) {
      debug('API Response: $url - Status: $statusCode${body != null ? '\nBody: $body' : ''}', tag: 'API');
    }
  }
  
  /// Logs provider state changes
  static void providerStateChange(String providerName, String state) {
    if (kDebugMode) {
      debug('Provider State Change: $providerName - $state', tag: 'Provider');
    }
  }
  
  /// Logs navigation events
  static void navigation(String from, String to) {
    if (kDebugMode) {
      debug('Navigation: $from -> $to', tag: 'Navigation');
    }
  }
  
  /// Logs database operations
  static void database(String operation, {String? table, Object? error}) {
    if (error != null) {
      LoggerService.error('Database Error: $operation${table != null ? ' on $table' : ''}', 
          tag: 'Database', error: error);
    } else if (kDebugMode) {
      debug('Database Operation: $operation${table != null ? ' on $table' : ''}', tag: 'Database');
    }
  }
}
