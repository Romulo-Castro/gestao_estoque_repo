// frontend/lib/providers/customer_provider.dart
import "package:flutter/foundation.dart";
import "/models/customer_model.dart";
import "/services/api_service.dart";

class CustomerProvider with ChangeNotifier {
  final ApiService _apiService;
  int? _storeId;

  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Construtor padrão para uso com ProxyProvider
  CustomerProvider() : _apiService = ApiService(), _storeId = null;

  // Método para atualizar o token de autenticação
  void updateAuthToken(String? token) {
    _apiService.setAuthToken(token);
    debugPrint("[CustomerProvider] Token atualizado: ${token != null ? 'presente' : 'nulo'}");
  }

  // Método para definir o ID da loja atual
  void setStoreId(int? storeId) {
    if (_storeId == storeId) return;
    _storeId = storeId;
    if (storeId != null && storeId > 0) {
      fetchCustomers();
    } else {
      _customers = [];
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }

  void _setError(String errorMsg) {
    _error = errorMsg;
    _isLoading = false;
    notifyListeners();
    debugPrint("CustomerProvider Error (Store: $_storeId): $errorMsg");
  }

  Future<void> fetchCustomers() async {
    if (_storeId == null || _storeId! <= 0) {
      _setError("ID da loja inválido para buscar clientes.");
      return;
    }
    _setLoading(true);
    try {
      _customers = await _apiService.fetchCustomers(_storeId!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _customers = [];
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    _setLoading(true);
    try {
      final newCustomer = await _apiService.createCustomer(
        _storeId!,
        customer,
      );
      _customers.add(newCustomer);
      _isLoading = false;
      notifyListeners();
      return newCustomer;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<Customer> updateCustomer(int customerId, Customer customer) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    _setLoading(true);
    try {
      final updatedCustomer = await _apiService.updateCustomer(
        _storeId!,
        customerId,
        customer,
      );
      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _customers[index] = updatedCustomer;
      }
      _isLoading = false;
      notifyListeners();
      return updatedCustomer;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> deleteCustomer(int customerId) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    _setLoading(true);
    try {
      await _apiService.deleteCustomer(_storeId!, customerId);
      _customers.removeWhere((c) => c.id == customerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }
}
