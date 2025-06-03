// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Para jsonEncode e jsonDecode
import '../services/api_service.dart'; // Ajuste o caminho se necessário
import '../models/user_model.dart'; // Ajuste o caminho se necessário

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiService) {
    _loadStoredAuth();
    print("AuthProvider: Inicializado. Tentando carregar auth armazenado.");
  }

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    final storedUserJson = prefs.getString('user_data');

    print("AuthProvider: _loadStoredAuth - Token: $storedToken, UserJSON: $storedUserJson");

    if (storedToken != null && storedUserJson != null) {
      try {
        _token = storedToken;
        _user = User.fromJson(jsonDecode(storedUserJson));
        _apiService.updateAuthToken(storedToken);
        print("AuthProvider: Auth carregado do SharedPreferences. User: ${_user?.name}");
      } catch (e) {
        print("AuthProvider: Erro ao decodificar user_data do SharedPreferences: $e");
        // Limpar dados inválidos
        await prefs.remove('auth_token');
        await prefs.remove('user_data');
        _token = null;
        _user = null;
      }
      notifyListeners();
    } else {
       print("AuthProvider: Nenhum auth encontrado no SharedPreferences.");
    }
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null && _user != null) {
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));
      print("AuthProvider: Auth salvo no SharedPreferences. Token: $_token");
    } else {
      // Se token ou user for nulo, remover do storage
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      print("AuthProvider: Token ou User nulo, removendo do SharedPreferences.");
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("AuthProvider: Chamando apiService.login com email: $email"); // DEBUG
      final response = await _apiService.login(email, password);
      print("AuthProvider: Resposta da API para login: $response"); // DEBUG

      // Verificar se a resposta contém 'token' e 'user'
      if (response.containsKey('token') && response.containsKey('user')) {
        _token = response['token'];
        _user = User.fromJson(response['user']); // Certifique-se que User.fromJson está robusto

        // DEBUG: Verifique se _token e _user foram preenchidos
        print("AuthProvider: Token recebido: $_token, User: ${_user?.name}, Email: ${_user?.email}");

        if (_token == null || _user == null) {
          _isLoading = false;
          _error = "Falha ao processar resposta do login (token ou user nulo).";
          notifyListeners();
          print("AuthProvider: Erro - Token ou User nulo após decodificação.");
          return false;
        }

        _apiService.updateAuthToken(_token!);
        await _saveAuthData();
        _isLoading = false;
        notifyListeners();
        print("AuthProvider: Login bem-sucedido, retornando true"); // DEBUG
        return true;
      } else {
        _isLoading = false;
        _error = response['message'] ?? "Resposta inesperada do servidor ao fazer login.";
        notifyListeners();
        print("AuthProvider: Erro - Resposta do login não contém 'token' ou 'user'. Mensagem: $_error");
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst("Exception: ", ""); // Remove o "Exception: " prefixo
      print("AuthProvider: Erro no login (catch): $_error"); // DEBUG
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("AuthProvider: Chamando apiService.register"); // DEBUG
      final response = await _apiService.register(name, email, password);
      print("AuthProvider: Resposta da API para registro: $response"); // DEBUG

      if (response.containsKey('token') && response.containsKey('user')) {
        _token = response['token'];
        _user = User.fromJson(response['user']);
        _apiService.updateAuthToken(_token!);
        await _saveAuthData();
        _isLoading = false;
        notifyListeners();
        print("AuthProvider: Registro bem-sucedido");
        return true;
      } else {
        _isLoading = false;
        _error = response['message'] ?? "Resposta inesperada do servidor ao registrar.";
        notifyListeners();
        print("AuthProvider: Erro - Resposta do registro não contém 'token' ou 'user'. Mensagem: $_error");
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst("Exception: ", "");
      print("AuthProvider: Erro no registro (catch): $_error");
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    print("AuthProvider: Iniciando logout.");
    _token = null;
    _user = null;
    // final prefs = await SharedPreferences.getInstance(); // Já chamado em _saveAuthData
    // prefs.remove('auth_token');
    // prefs.remove('user_data');
    await _saveAuthData(); // Chama o saveAuthData que irá remover se token/user forem nulos
    _apiService.updateAuthToken(null);
    _error = null; // Limpar qualquer erro anterior
    _isLoading = false; // Garantir que o loading não fique preso
    notifyListeners();
    print("AuthProvider: Logout concluído. isAuthenticated: $isAuthenticated");
  }

  Future<void> fetchUserData() async {
    if (_token == null) {
      print("AuthProvider: fetchUserData - Token é nulo, não buscando dados do usuário.");
      return;
    }

    _isLoading = true;
    // Não notificar listeners aqui pode evitar um piscar desnecessário da UI
    // se o usuário já estiver carregado do SharedPreferences
    // notifyListeners();

    try {
      print("AuthProvider: fetchUserData - Chamando apiService.fetchUserData");
      final userData = await _apiService.fetchUserData();
      _user = User.fromJson(userData);
      await _saveAuthData(); // Atualiza o usuário no SharedPreferences se houver mudanças
      _isLoading = false;
      _error = null;
      notifyListeners();
      print("AuthProvider: fetchUserData - Dados do usuário buscados: ${_user?.name}");
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst("Exception: ", "");
      print("AuthProvider: fetchUserData - Erro ao buscar dados do usuário: $_error");
      // Considerar fazer logout se o token for inválido (ex: erro 401)
      if (_error != null && (_error!.contains("Token inválido") || _error!.contains("Usuário não encontrado"))) {
         print("AuthProvider: fetchUserData - Token inválido detectado, fazendo logout.");
         await logout(); // Isso já notifica os listeners
      } else {
         notifyListeners();
      }
    }
  }

  void clearError() {
    if (_error != null) {
      print("AuthProvider: Limpando erro: $_error");
      _error = null;
      notifyListeners();
    }
  }
}

// Certifique-se de que seu modelo User tenha os métodos toJson e fromJson corretos.
// Exemplo básico de user_model.dart:
/*
// lib/models/user_model.dart
class User {
  final int id;
  final String name;
  final String email;
  // Adicione outros campos conforme necessário (e.g., createdAt, updatedAt)

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
*/