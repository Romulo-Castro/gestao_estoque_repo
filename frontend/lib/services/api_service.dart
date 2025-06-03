// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io'; // Para File, se usar upload de imagem
import 'package:http/http.dart' as http;
// Importe seus modelos aqui se precisar retornar tipos específicos
// import '../models/document_model.dart';
// import '../models/stock_item.dart';
// import '../models/store_model.dart';
// ... e outros

class ApiService {
  // ATENÇÃO: Ajuste o IP se necessário.
  // 10.0.2.2 é para emulador Android se o backend estiver no localhost da máquina host.
  // Se o backend e o app Flutter estiverem rodando na mesma máquina (ex: Flutter Web ou Desktop), use localhost.
  // Se o app estiver em um dispositivo físico, use o IP da sua máquina na rede local.
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  // static const String baseUrl = 'http://localhost:3000/api'; // Para iOS ou web/desktop
  String? _authToken;

  ApiService() {
    print("ApiService: Instanciado com baseUrl: $baseUrl");
  }

  void updateAuthToken(String? token) {
    _authToken = token;
    print("ApiService: Auth token atualizado para: ${_authToken == null ? 'null' : 'presente'}");
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8', // Adicionado charset
      'Accept': 'application/json', // Bom para garantir que o servidor saiba que esperamos JSON
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    // print("ApiService: Gerando headers: $headers"); // Pode ser muito verboso
    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    print("ApiService: _handleResponse - Status: ${response.statusCode}, Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}..."); // Log truncado do body

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        print("ApiService: _handleResponse (Sucesso) - Corpo da resposta vazio.");
        return {}; // Retorna um mapa vazio se o corpo estiver vazio
      }
      try {
        final decodedBody = json.decode(response.body);
        print("ApiService: _handleResponse (Sucesso) - Corpo decodificado: $decodedBody");
        return decodedBody;
      } catch (e) {
        print("ApiService: _handleResponse (Sucesso) - Erro ao decodificar JSON: $e. Corpo original: ${response.body}");
        throw Exception('Falha ao decodificar resposta do servidor.');
      }
    } else {
      String errorMessage = 'Erro na requisição (${response.statusCode})';
      if (response.body.isNotEmpty) {
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else {
            errorMessage = response.body; // Se não for um JSON com 'message'
          }
        } catch (e) {
          // Se o corpo do erro não for JSON válido
          errorMessage = 'Erro do servidor: ${response.statusCode}. Detalhes não puderam ser lidos.';
          print("ApiService: _handleResponse (Erro) - Não foi possível decodificar corpo do erro: ${response.body}");
        }
      }
      print("ApiService: _handleResponse (Erro) - Mensagem: $errorMessage");
      throw Exception(errorMessage);
    }
  }

  // Autenticação
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final body = json.encode({
      'email': email,
      'password': password,
    });
    print("ApiService: Enviando POST para $url com body: $body"); // DEBUG

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: body,
      ).timeout(const Duration(seconds: 15), onTimeout: () { // Adiciona timeout
          print("ApiService: Timeout na requisição de login para $url");
          throw Exception('Tempo limite da requisição excedido ao tentar fazer login.');
      });
      return await _handleResponse(response);
    } on SocketException catch (e) {
        print("ApiService: Erro de Socket (provavelmente sem conexão) no login: $e");
        throw Exception("Erro de conexão. Verifique sua internet e se o servidor está acessível.");
    } on http.ClientException catch (e) {
        print("ApiService: Erro de Cliente HTTP no login: $e");
        throw Exception("Erro ao comunicar com o servidor: ${e.message}");
    } catch (e) {
      print("ApiService: Erro desconhecido na chamada http.post para login: $e");
      // Re-throw a exceção para ser tratada pelo AuthProvider
      // Se já for uma Exception com mensagem útil, apenas re-throw.
      if (e is Exception) {
        rethrow;
      }
      throw Exception("Erro desconhecido ao tentar fazer login: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final body = json.encode({
      'name': name,
      'email': email,
      'password': password,
    });
    print("ApiService: Enviando POST para $url com body: $body");

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: body,
      ).timeout(const Duration(seconds: 15));
      return await _handleResponse(response);
    } on SocketException catch (e) {
        print("ApiService: Erro de Socket (provavelmente sem conexão) no registro: $e");
        throw Exception("Erro de conexão. Verifique sua internet e se o servidor está acessível.");
    } on http.ClientException catch (e) {
        print("ApiService: Erro de Cliente HTTP no registro: $e");
        throw Exception("Erro ao comunicar com o servidor: ${e.message}");
    } catch (e) {
      print("ApiService: Erro desconhecido na chamada http.post para registro: $e");
      if (e is Exception) rethrow;
      throw Exception("Erro desconhecido ao tentar registrar: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    final url = Uri.parse('$baseUrl/auth/me');
    print("ApiService: Enviando GET para $url");

    try {
      final response = await http.get(
        url,
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return await _handleResponse(response);
    } on SocketException catch (e) {
        print("ApiService: Erro de Socket (provavelmente sem conexão) em fetchUserData: $e");
        throw Exception("Erro de conexão ao buscar dados do usuário.");
    } on http.ClientException catch (e) {
        print("ApiService: Erro de Cliente HTTP em fetchUserData: $e");
        throw Exception("Erro ao comunicar com o servidor para buscar dados do usuário: ${e.message}");
    } catch (e) {
      print("ApiService: Erro desconhecido na chamada http.get para fetchUserData: $e");
      if (e is Exception) rethrow;
      throw Exception("Erro desconhecido ao buscar dados do usuário: ${e.toString()}");
    }
  }

  // Adicione outros métodos da API aqui (stores, stock, documents, etc.)
  // ...
}