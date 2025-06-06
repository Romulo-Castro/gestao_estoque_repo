// lib/utils/error_handler.dart
import 'package:flutter/material.dart';

/// Centralized error handling utility for the Flutter frontend
class ErrorHandler {
  /// Standard error messages that can be localized later
  static const Map<String, String> _errorMessages = {
    'network_error': 'Erro de conexão. Verifique sua internet.',
    'timeout_error': 'Tempo limite esgotado. Tente novamente.',
    'auth_error': 'Credenciais inválidas ou sessão expirada.',
    'permission_error': 'Permissão negada para esta operação.',
    'not_found': 'Recurso não encontrado.',
    'validation_error': 'Dados inválidos. Verifique os campos.',
    'server_error': 'Erro interno do servidor. Tente mais tarde.',
    'unknown_error': 'Erro inesperado. Tente novamente.',
  };

  /// Convert exception to user-friendly message
  static String handleError(dynamic error) {
    if (error == null) return _errorMessages['unknown_error']!;

    final errorString = error.toString().toLowerCase();
    
    // Network and timeout errors
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return _errorMessages['network_error']!;
    }
    
    if (errorString.contains('timeout') || 
        errorString.contains('timed out')) {
      return _errorMessages['timeout_error']!;
    }
    
    // Authentication errors
    if (errorString.contains('401') || 
        errorString.contains('unauthorized') ||
        errorString.contains('credenciais inválidas') ||
        errorString.contains('token inválido')) {
      return _errorMessages['auth_error']!;
    }
    
    // Permission errors
    if (errorString.contains('403') || 
        errorString.contains('forbidden') ||
        errorString.contains('permissão negada') ||
        errorString.contains('acesso negado')) {
      return _errorMessages['permission_error']!;
    }
    
    // Not found errors
    if (errorString.contains('404') || 
        errorString.contains('not found') ||
        errorString.contains('não encontrado')) {
      return _errorMessages['not_found']!;
    }
    
    // Validation errors
    if (errorString.contains('400') || 
        errorString.contains('bad request') ||
        errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('obrigatório')) {
      return _errorMessages['validation_error']!;
    }
    
    // Server errors
    if (errorString.contains('500') || 
        errorString.contains('internal server') ||
        errorString.contains('server error')) {
      return _errorMessages['server_error']!;
    }
    
    // Return the original error if it's already user-friendly
    // Remove "Exception: " prefix if present
    String cleanError = error.toString();
    if (cleanError.startsWith('Exception: ')) {
      cleanError = cleanError.substring(11);
    }
    
    // If error is too technical, use generic message
    if (cleanError.length > 100 || 
        cleanError.contains('stack trace') ||
        cleanError.contains('setState')) {
      return _errorMessages['unknown_error']!;
    }
    
    return cleanError;
  }

  /// Show error in a SnackBar with consistent styling
  static void showErrorSnackBar(BuildContext context, dynamic error, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    final message = handleError(error);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show success message in a SnackBar with consistent styling
  static void showSuccessSnackBar(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show loading SnackBar for long operations
  static void showLoadingSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 10), // Long duration for loading
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Log error for debugging (can be enhanced with crash reporting)
  static void logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    debugPrint('ERROR in $operation: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Check if error indicates authentication failure
  static bool isAuthError(dynamic error) {
    if (error == null) return false;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('401') || 
           errorString.contains('unauthorized') ||
           errorString.contains('credenciais inválidas') ||
           errorString.contains('token inválido') ||
           errorString.contains('auth');
  }

  /// Check if error indicates network failure
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') || 
           errorString.contains('connection') ||
           errorString.contains('socket') ||
           errorString.contains('timeout');
  }

  /// Show error dialog for critical errors
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    dynamic error, {
    List<Widget>? actions,
  }) async {
    if (!context.mounted) return;
    
    final message = handleError(error);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: actions ?? [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

/// Mixin for providers to standardize error handling
mixin ErrorHandlingMixin on ChangeNotifier {
  String? _error;
  bool _isLoading = false;

  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;

  /// Set loading state and clear errors
  void setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }

  /// Set error state and stop loading
  void setError(dynamic error, [String? operation]) {
    _error = ErrorHandler.handleError(error);
    _isLoading = false;
    notifyListeners();
    
    if (operation != null) {
      ErrorHandler.logError(operation, error);
    }
  }

  /// Clear error state
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Wrapper for async operations with error handling
  Future<T?> handleAsyncOperation<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    setLoading(true);
    try {
      final result = await operation();
      setLoading(false);
      return result;
    } catch (error, stackTrace) {
      setError(error, operationName);
      ErrorHandler.logError(operationName, error, stackTrace);
      return null;
    }
  }
}
