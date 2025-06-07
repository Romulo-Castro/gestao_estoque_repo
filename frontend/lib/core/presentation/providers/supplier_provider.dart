// frontend/lib/providers/supplier_provider.dart
import "package:flutter/widgets.dart";
import "../../data/models/supplier_model.dart";
import "../../data/datasources/api_service.dart";
import "../../../shared/utils/error_handler.dart";

class SupplierProvider with ChangeNotifier, ErrorHandlingMixin {
  final ApiService _apiService;
  int? _storeId;

  List<Supplier> _suppliers = [];

  List<Supplier> get suppliers => _suppliers;

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
      // Use postFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchSuppliers();
      });
    } else {
      _suppliers = [];
      notifyListeners();
    }
  }

  Future<void> fetchSuppliers() async {
    if (_storeId == null || _storeId! <= 0) {
      setError("ID da loja inválido para buscar fornecedores.", 'fetchSuppliers');
      return;
    }
    
    await handleAsyncOperation(() async {
      _suppliers = await _apiService.fetchSuppliers(_storeId!);
      debugPrint("[SupplierProvider] Fornecedores carregados: ${_suppliers.length}");
    }, 'fetchSuppliers');
    
    // Clear suppliers on error
    if (hasError) {
      _suppliers = [];
    }
  }

  Future<Supplier?> createSupplier(Supplier supplier) async {
    if (_storeId == null || _storeId! <= 0) {
      setError('ID da loja inválido.', 'createSupplier');
      return null;
    }
    
    return await handleAsyncOperation(() async {
      final newSupplier = await _apiService.createSupplier(_storeId!, supplier);
      _suppliers.add(newSupplier);
      debugPrint("[SupplierProvider] Fornecedor criado: ${newSupplier.name} (ID: ${newSupplier.id})");
      return newSupplier;
    }, 'createSupplier');
  }

  Future<Supplier?> updateSupplier(int supplierId, Supplier supplier) async {
    if (_storeId == null || _storeId! <= 0) {
      setError('ID da loja inválido.', 'updateSupplier');
      return null;
    }
    
    return await handleAsyncOperation(() async {
      final updatedSupplier = await _apiService.updateSupplier(_storeId!, supplierId, supplier);
      final index = _suppliers.indexWhere((s) => s.id == supplierId);
      if (index != -1) {
        _suppliers[index] = updatedSupplier;
      }
      debugPrint("[SupplierProvider] Fornecedor atualizado: ${updatedSupplier.name} (ID: $supplierId)");
      return updatedSupplier;
    }, 'updateSupplier');
  }
  Future<void> deleteSupplier(int supplierId) async {
    if (_storeId == null || _storeId! <= 0) {
      setError('ID da loja inválido.', 'deleteSupplier');
      return;
    }
    
    await handleAsyncOperation(() async {
      await _apiService.deleteSupplier(_storeId!, supplierId);
      _suppliers.removeWhere((s) => s.id == supplierId);
      debugPrint("[SupplierProvider] Fornecedor excluído (ID: $supplierId)");
    }, 'deleteSupplier');
  }
}
