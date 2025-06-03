// frontend/lib/providers/supplier_provider.dart
import "package:flutter/foundation.dart";
import "/models/supplier_model.dart";
import "/services/api_service.dart";

class SupplierProvider with ChangeNotifier {
  final ApiService _apiService;
  int? _storeId;

  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String? _error;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Construtor padrão para uso com ProxyProvider
  SupplierProvider() : _apiService = ApiService(), _storeId = null;

  // Método para atualizar o token de autenticação
  void updateAuthToken(String? token) {
    _apiService.setAuthToken(token);
    debugPrint("[SupplierProvider] Token atualizado: ${token != null ? 'presente' : 'nulo'}");
  }

  // Método para definir o ID da loja atual
  void setStoreId(int? storeId) {
    if (_storeId == storeId) return;
    _storeId = storeId;
    if (storeId != null && storeId > 0) {
      fetchSuppliers();
    } else {
      _suppliers = [];
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
    debugPrint("SupplierProvider Error (Store: $_storeId): $errorMsg");
  }

  Future<void> fetchSuppliers() async {
    if (_storeId == null || _storeId! <= 0) {
      _setError("ID da loja inválido para buscar fornecedores.");
      return;
    }
    _setLoading(true);
    try {
      _suppliers = await _apiService.fetchSuppliers(_storeId!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _suppliers = [];
    }
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    _setLoading(true);
    try {
      final newSupplier = await _apiService.createSupplier(
        _storeId!,
        supplier,
      );
      _suppliers.add(newSupplier);
      _isLoading = false;
      notifyListeners();
      return newSupplier;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<Supplier> updateSupplier(int supplierId, Supplier supplier) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    _setLoading(true);
    try {
      final updatedSupplier = await _apiService.updateSupplier(
        _storeId!,
        supplierId,
        supplier,
      );
      final index = _suppliers.indexWhere((s) => s.id == supplierId);
      if (index != -1) {
        _suppliers[index] = updatedSupplier;
      }
      _isLoading = false;
      notifyListeners();
      return updatedSupplier;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> deleteSupplier(int supplierId) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    _setLoading(true);
    try {
      await _apiService.deleteSupplier(_storeId!, supplierId);
      _suppliers.removeWhere((s) => s.id == supplierId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }
}
