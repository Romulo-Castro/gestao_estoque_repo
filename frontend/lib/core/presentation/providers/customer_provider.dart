// frontend/lib/core/presentation/providers/customer_provider.dart
import "package:flutter/widgets.dart";
import "../../data/models/customer_model.dart";
import "../../data/datasources/api_service.dart";
import "../../../shared/utils/error_handler.dart";

class CustomerProvider with ChangeNotifier, ErrorHandlingMixin {
  final ApiService _apiService;
  int? _storeId;

  List<Customer> _customers = [];

  List<Customer> get customers => _customers;

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
      // Use postFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchCustomers();
      });
    } else {
      _customers = [];
      notifyListeners();
    }
  }

  Future<void> fetchCustomers() async {
    if (_storeId == null || _storeId! <= 0) {
      setError("ID da loja inválido para buscar clientes.", 'fetchCustomers');
      return;
    }
    
    await handleAsyncOperation(() async {
      _customers = await _apiService.fetchCustomers(_storeId!);
      debugPrint("[CustomerProvider] Clientes carregados: ${_customers.length}");
    }, 'fetchCustomers');
    
    // Clear customers on error
    if (hasError) {
      _customers = [];
    }
  }

  Future<Customer?> createCustomer(Customer customer) async {
    if (_storeId == null || _storeId! <= 0) {
      setError('ID da loja inválido.', 'createCustomer');
      return null;
    }
    
    return await handleAsyncOperation(() async {
      final newCustomer = await _apiService.createCustomer(_storeId!, customer);
      _customers.add(newCustomer);
      debugPrint("[CustomerProvider] Cliente criado: ${newCustomer.name} (ID: ${newCustomer.id})");
      return newCustomer;
    }, 'createCustomer');
  }

  Future<Customer?> updateCustomer(int customerId, Customer customer) async {
    if (_storeId == null || _storeId! <= 0) {
      setError('ID da loja inválido.', 'updateCustomer');
      return null;
    }
    
    return await handleAsyncOperation(() async {
      final updatedCustomer = await _apiService.updateCustomer(_storeId!, customerId, customer);
      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _customers[index] = updatedCustomer;
      }
      debugPrint("[CustomerProvider] Cliente atualizado: ${updatedCustomer.name} (ID: $customerId)");
      return updatedCustomer;
    }, 'updateCustomer');
  }

  Future<void> deleteCustomer(int customerId) async {
    if (_storeId == null || _storeId! <= 0) {
      setError('ID da loja inválido.', 'deleteCustomer');
      return;
    }
    
    await handleAsyncOperation(() async {
      await _apiService.deleteCustomer(_storeId!, customerId);
      _customers.removeWhere((c) => c.id == customerId);
      debugPrint("[CustomerProvider] Cliente excluído (ID: $customerId)");
    }, 'deleteCustomer');
  }
}
