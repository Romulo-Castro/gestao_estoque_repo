// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io'; // Para File, se usar upload de imagem
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// Importe seus modelos aqui se precisar retornar tipos específicos
import '../models/document_model.dart';
import '../models/stock_item.dart';
import '../models/store_model.dart';
import '../models/customer_model.dart';
import '../models/item_group_model.dart';
import '../models/supplier_model.dart';

class ApiService {
  // ATENÇÃO: Ajuste o IP se necessário.
  // 10.0.2.2 é para emulador Android se o backend estiver no localhost da máquina host.
  // Se o backend e o app Flutter estiverem rodando na mesma máquina (ex: Flutter Web ou Desktop), use localhost.
  // Se o app estiver em um dispositivo físico, use o IP da sua máquina na rede local.
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  // static const String baseUrl = 'http://localhost:3000/api'; // Para iOS ou web/desktop
  String? _authToken;

  ApiService() {
    // print("ApiService: Instanciado com baseUrl: $baseUrl");
  }

  void updateAuthToken(String? token) {
    _authToken = token;
    // print("ApiService: Auth token atualizado para: ${_authToken == null ? 'null' : 'presente'}");
  }

  // Alias for backward compatibility
  void setAuthToken(String? token) => updateAuthToken(token);

  // Getter for the current auth token
  String? get token => _authToken;

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
  }  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {}; // Retorna um mapa vazio se o corpo estiver vazio
      }
      try {
        final decodedBody = json.decode(response.body);
        
        // Se a resposta segue o padrão { status, message, data }
        if (decodedBody is Map && 
            decodedBody.containsKey('status') && 
            decodedBody['status'] == 'success' && 
            decodedBody.containsKey('data')) {
          // Retorna apenas o objeto 'data'
          return decodedBody['data'];
        }
        
        // Caso contrário, retorna o corpo completo        return decodedBody;
      } catch (e) {
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
        }      }
      debugPrint("ApiService: _handleResponse (Erro) - Mensagem: $errorMessage");
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
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: body,
      ).timeout(const Duration(seconds: 15));
      return await _handleResponse(response);
    } on SocketException {
      throw Exception('Erro de conexão. Verifique sua internet e se o servidor está acessível.');
    } on http.ClientException catch (e) {
      throw Exception('Erro ao comunicar com o servidor: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final body = json.encode({
      'name': name,
      'email': email,
      'password': password,
    });
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: body,
      ).timeout(const Duration(seconds: 15));
      return await _handleResponse(response);
    } on SocketException {
      throw Exception('Erro de conexão. Verifique sua internet e se o servidor está acessível.');
    } on http.ClientException catch (e) {
      throw Exception('Erro ao comunicar com o servidor: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    final url = Uri.parse('$baseUrl/auth/me');
    // print("ApiService: Enviando GET para $url");

    try {
      final response = await http.get(
        url,
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return await _handleResponse(response);
    } on SocketException {
        // print("ApiService: Erro de Socket (provavelmente sem conexão) em fetchUserData: $e");
        throw Exception("Erro de conexão ao buscar dados do usuário.");
    } on http.ClientException catch (e) {
        // print("ApiService: Erro de Cliente HTTP em fetchUserData: $e");
        throw Exception("Erro ao comunicar com o servidor para buscar dados do usuário: ${e.message}");
    } catch (e) {
      // print("ApiService: Erro desconhecido na chamada http.get para fetchUserData: $e");
      if (e is Exception) rethrow;
      throw Exception("Erro desconhecido ao buscar dados do usuário: ${e.toString()}");
    }
  }

  // Stores endpoints
  Future<List<Store>> fetchUserStores() async {
    final url = Uri.parse('$baseUrl/stores');
    final response = await http.get(url, headers: _headers);
    final data = await _handleResponse(response) as List;
    return data.map((e) => Store.fromJson(e)).toList();
  }
  Future<Store> createStore(String name, String? address) async {
    final url = Uri.parse('$baseUrl/stores');
    final response = await http.post(
      url,
      headers: _headers,
      body: json.encode({'name': name, 'address': address}),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return Store.fromJson(data);
  }

  Future<Store> updateStore(int storeId, String name, String? address) async {
    final url = Uri.parse('$baseUrl/stores/$storeId');
    final response = await http.put(
      url,
      headers: _headers,
      body: json.encode({'name': name, 'address': address}),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return Store.fromJson(data);
  }

  Future<void> deleteStore(int storeId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId');
    final response = await http.delete(url, headers: _headers);
    await _handleResponse(response);
  }

  // Customers endpoints
  Future<List<Customer>> fetchCustomers(int storeId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/customers');
    final response = await http.get(url, headers: _headers);
    final data = await _handleResponse(response) as List;
    return data.map((e) => Customer.fromJson(e)).toList();
  }

  Future<Customer> createCustomer(int storeId, Customer customer) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/customers');
    final response = await http.post(
      url,
      headers: _headers,
      body: json.encode(customer.toJson()),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return Customer.fromJson(data);
  }

  Future<Customer> updateCustomer(int storeId, int customerId, Customer customer) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/customers/$customerId');
    final response = await http.put(
      url,
      headers: _headers,
      body: json.encode(customer.toJson()),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return Customer.fromJson(data);
  }

  Future<void> deleteCustomer(int storeId, int customerId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/customers/$customerId');
    final response = await http.delete(url, headers: _headers);
    await _handleResponse(response);
  }

  // Item Groups endpoints
  Future<List<ItemGroup>> fetchItemGroups(int storeId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/groups');
    final response = await http.get(url, headers: _headers);
    final data = await _handleResponse(response) as List;
    return data.map((e) => ItemGroup.fromJson(e)).toList();
  }

  Future<ItemGroup> createItemGroup(int storeId, ItemGroup group) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/groups');
    final response = await http.post(
      url,
      headers: _headers,
      body: json.encode(group.toJson()),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return ItemGroup.fromJson(data);
  }

  Future<ItemGroup> updateItemGroup(int storeId, int groupId, ItemGroup group) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/groups/$groupId');
    final response = await http.put(
      url,
      headers: _headers,
      body: json.encode(group.toJson()),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return ItemGroup.fromJson(data);
  }

  Future<void> deleteItemGroup(int storeId, int groupId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/groups/$groupId');
    final response = await http.delete(url, headers: _headers);
    await _handleResponse(response);
  }

  // Stock Items endpoints
  Future<List<StockItem>> fetchStockItems(int storeId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/stock');
    final response = await http.get(url, headers: _headers);
    final data = await _handleResponse(response) as List;
    return data.map((e) => StockItem.fromJson(e)).toList();
  }

  Future<StockItem> createStockItem(int storeId, StockItem item) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/stock');
    final response = await http.post(
      url,
      headers: _headers,
      body: json.encode(item.toJson()),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return StockItem.fromJson(data);
  }

  Future<StockItem> updateStockItem(int storeId, int itemId, StockItem item) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/stock/$itemId');
    final response = await http.put(
      url,
      headers: _headers,
      body: json.encode(item.toJson()),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return StockItem.fromJson(data);
  }

  Future<void> deleteStockItem(int storeId, int itemId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/stock/$itemId');
    final response = await http.delete(url, headers: _headers);
    await _handleResponse(response);
  }
  Future<StockItem> uploadImage(int storeId, int itemId, File file) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/stock/$itemId/image');
    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('productImage', file.path));
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return StockItem.fromJson(data);
  }
  
  Future<StockItem> deleteItemImage(int storeId, int itemId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/stock/$itemId/image');
    final response = await http.delete(url, headers: _headers);
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return StockItem.fromJson(data);
  }

  // Documents endpoints
  Future<List<Document>> fetchDocuments(int storeId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/documents');
    final response = await http.get(url, headers: _headers);
    final data = await _handleResponse(response) as List;
    return data.map((e) => Document.fromJson(e)).toList();
  }

  Future<Document> fetchDocumentById(int storeId, int documentId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/documents/$documentId');
    final response = await http.get(url, headers: _headers);
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return Document.fromJson(data);
  }

  Future<Document> createDocument(int storeId, Document document) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/documents');
    final response = await http.post(
      url,
      headers: _headers,
      body: json.encode(document.toJson()),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return Document.fromJson(data);
  }

  Future<Document> updateDocumentHeader(int storeId, int documentId, Document document) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/documents/$documentId');
    final response = await http.put(
      url,
      headers: _headers,
      body: json.encode(document.toJson()),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return Document.fromJson(data);
  }

  Future<void> cancelDocument(int storeId, int documentId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/documents/$documentId');
    final response = await http.delete(url, headers: _headers);
    await _handleResponse(response);
  }

  Future<void> processDocument(int storeId, int documentId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/documents/$documentId/process');
    final response = await http.post(url, headers: _headers);
    await _handleResponse(response);
  }

  Future<List<Document>> fetchDocumentsWithFilters(int storeId, Map<String, dynamic> filters) async {
    final queryString = Uri(queryParameters: filters.map((k, v) => MapEntry(k, v.toString()))).query;
    final url = Uri.parse('$baseUrl/stores/$storeId/documents?$queryString');
    final response = await http.get(url, headers: _headers);
    final data = await _handleResponse(response) as List;
    return data.map((e) => Document.fromJson(e)).toList();
  }

  Future<Document> updateDocument(int storeId, int documentId, Document document) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/documents/$documentId');
    final response = await http.put(
      url,
      headers: _headers,
      body: json.encode(document.toJson()),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return Document.fromJson(data);
  }

  Future<Document> updateDocumentStatus(int storeId, int documentId, String status) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/documents/$documentId/status');
    final response = await http.patch(
      url,
      headers: _headers,
      body: json.encode({'status': status}),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return Document.fromJson(data);
  }

  Future<void> deleteDocument(int storeId, int documentId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/documents/$documentId');
    final response = await http.delete(url, headers: _headers);
    await _handleResponse(response);
  }

  // Suppliers endpoints
  Future<List<Supplier>> fetchSuppliers(int storeId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/suppliers');
    final response = await http.get(url, headers: _headers);
    final data = await _handleResponse(response) as List;
    return data.map((e) => Supplier.fromJson(e)).toList();
  }

  Future<Supplier> createSupplier(int storeId, Supplier supplier) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/suppliers');
    final response = await http.post(
      url,
      headers: _headers,
      body: json.encode(supplier.toJson()),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return Supplier.fromJson(data);
  }

  Future<Supplier> updateSupplier(int storeId, int supplierId, Supplier supplier) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/suppliers/$supplierId');
    final response = await http.put(
      url,
      headers: _headers,
      body: json.encode(supplier.toJson()),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return Supplier.fromJson(data);
  }

  Future<void> deleteSupplier(int storeId, int supplierId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/suppliers/$supplierId');
    final response = await http.delete(url, headers: _headers);
    await _handleResponse(response);
  }
}