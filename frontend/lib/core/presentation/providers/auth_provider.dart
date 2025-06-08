// lib/core/presentation/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Para jsonEncode e jsonDecode
import '../../data/datasources/api_service.dart'; // Ajuste o caminho se necessário
import '../../data/models/user_model.dart'; // Ajuste o caminho se necessário
import '../../../shared/utils/error_handler.dart'; // Import error handling utility

class AuthProvider with ChangeNotifier, ErrorHandlingMixin {
  final ApiService _apiService;
  User? _user;
  String? _token;

  AuthProvider(this._apiService) {
    _loadStoredAuth();
    // print("AuthProvider: Inicializado. Tentando carregar auth armazenado.");
  }

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;

  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    final storedUserJson = prefs.getString('user_data');

    // print("AuthProvider: _loadStoredAuth - Token: $storedToken, UserJSON: $storedUserJson");

    if (storedToken != null && storedUserJson != null) {
      try {
        _token = storedToken;
        _user = User.fromJson(jsonDecode(storedUserJson));
        _apiService.updateAuthToken(storedToken);
        // print("AuthProvider: Auth carregado do SharedPreferences. User: ${_user?.name}");
      } catch (e) {
        // print("AuthProvider: Erro ao decodificar user_data do SharedPreferences: $e");
        // Limpar dados inválidos
        await prefs.remove('auth_token');
        await prefs.remove('user_data');
        _token = null;
        _user = null;
        ErrorHandler.logError('_loadStoredAuth', e);
      }
      notifyListeners();
    } else {
       // print("AuthProvider: Nenhum auth encontrado no SharedPreferences.");
    }
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null && _user != null) {
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));
      // print("AuthProvider: Auth salvo no SharedPreferences. Token: $_token");
    } else {
      // Se token ou user for nulo, remover do storage
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      // print("AuthProvider: Token ou User nulo, removendo do SharedPreferences.");
    }
  }  Future<bool> login(String email, String password) async {
    return await handleAsyncOperation(() async {
      final response = await _apiService.login(email, password);

      // A resposta já foi processada pelo ApiService._handleResponse
      // e deve conter apenas o objeto 'data' com token e user
      if (response.containsKey('token') && 
          response.containsKey('user')) {
        
        _token = response['token'];
        _user = User.fromJson(response['user']);
        _apiService.updateAuthToken(_token!);
        await _saveAuthData();
        return true;
      }
      
      // Se chegou aqui, a resposta não está no formato esperado
      throw Exception("Resposta inválida do servidor.");
    }, 'login') ?? false;
  }

  Future<bool> register(String name, String email, String password) async {
    return await handleAsyncOperation(() async {      final response = await _apiService.register(name, email, password);

      // A resposta já foi processada pelo ApiService._handleResponse
      // e deve conter apenas o objeto 'data' com token e user
      if (response.containsKey('token') && 
          response.containsKey('user')) {
        
        _token = response['token'];
        _user = User.fromJson(response['user']);
        _apiService.updateAuthToken(_token!);        await _saveAuthData();
        return true;
      }
      
      // Se chegou aqui, a resposta não está no formato esperado
      throw Exception("Resposta inválida do servidor.");
    }, 'register') ?? false;
  }

  Future<void> logout() async {
    // print("AuthProvider: Fazendo logout...");
    _token = null;
    _user = null;
    await _saveAuthData(); // Chama o saveAuthData que irá remover se token/user forem nulos
    _apiService.updateAuthToken(null);
    clearError(); // Limpar qualquer erro anterior usando mixin
    setLoading(false); // Garantir que o loading não fique preso usando mixin
    // print("AuthProvider: Logout concluído. isAuthenticated: $isAuthenticated");
    notifyListeners();
  }

  Future<void> fetchUserData() async {
    if (_token == null) {
      // print("AuthProvider: fetchUserData - Token é nulo, não buscando dados do usuário.");
      return;
    }

    await handleAsyncOperation(() async {
      // print("AuthProvider: fetchUserData - Chamando apiService.fetchUserData");
      final userData = await _apiService.fetchUserData();
      _user = User.fromJson(userData);
      await _saveAuthData(); // Atualiza o usuário no SharedPreferences se houver mudanças
      // print("AuthProvider: fetchUserData - Dados do usuário buscados: ${_user?.name}");
    }, 'fetchUserData');

    // Handle auth errors specifically for user data fetch
    if (hasError && ErrorHandler.isAuthError(error)) {
      // print("AuthProvider: fetchUserData - Token inválido detectado, fazendo logout.");
      await logout(); // Isso já notifica os listeners
    }
  }

  /// Validates the current token by making a simple API call
  /// Returns true if token is valid, false otherwise
  /// Automatically logs out if token is invalid
  Future<bool> validateToken() async {
    if (_token == null) {
      return false;
    }

    bool isValid = false;
    await handleAsyncOperation(() async {
      // Try to fetch user data as a token validation
      final userData = await _apiService.fetchUserData();
      _user = User.fromJson(userData);
      await _saveAuthData();
      isValid = true;
      debugPrint("AuthProvider: Token validation successful");
    }, 'validateToken');

    // If validation failed due to auth error, logout
    if (hasError && ErrorHandler.isAuthError(error)) {
      debugPrint("AuthProvider: Token validation failed - token inválido, fazendo logout automático");
      await logout();
      return false;
    }

    return isValid;
  }

  /// Initialize authentication state - call this on app start
  Future<void> initializeAuth() async {
    debugPrint("AuthProvider: Inicializando autenticação...");
    
    if (_token != null) {
      // If we have a token, validate it
      final isValid = await validateToken();
      if (!isValid) {
        debugPrint("AuthProvider: Token armazenado é inválido, redirecionando para login");
      } else {
        debugPrint("AuthProvider: Token validado com sucesso");
      }
    } else {
      debugPrint("AuthProvider: Nenhum token encontrado, usuário precisa fazer login");
    }
  }
  
  /// Update user profile information and persist changes
  Future<void> updateUserProfile(User updatedUser) async {
    _user = updatedUser;
    await _saveAuthData();
    notifyListeners();
    debugPrint("AuthProvider: Perfil do usuário atualizado: ${_user?.name}");
  }
}