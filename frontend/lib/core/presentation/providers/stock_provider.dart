// lib/core/presentation/providers/stock_provider.dart
import "package:flutter/foundation.dart";
import "../../data/models/stock_item.dart";
import "../../data/datasources/api_service.dart";
import "../../../shared/utils/error_handler.dart";

class StockProvider with ChangeNotifier, ErrorHandlingMixin {
  final ApiService _apiService;
  int? _storeId;

  List<StockItem> _items = [];

  List<StockItem> get items => _items;

  // Construtor padrão para uso com ProxyProvider
  StockProvider() : _apiService = ApiService(), _storeId = null;

  // Método para atualizar o token de autenticação
  void updateAuthToken(String? token) {
    _apiService.setAuthToken(token);
    debugPrint("[StockProvider] Token atualizado: ${token != null ? 'presente' : 'nulo'}");
  }

  // Método para definir o ID da loja atual
  void setStoreId(int? storeId) {
    if (_storeId == storeId) return;
    _storeId = storeId;
    if (storeId != null && storeId > 0) {
      fetchStockItems();
    } else {
      _items = [];
      notifyListeners();
    }
  }

  Future<void> fetchStockItems() async {
    if (_storeId == null || _storeId! <= 0) {
      setError("ID da loja inválido para buscar itens.", 'fetchStockItems');
      return;
    }
    
    await handleAsyncOperation(() async {
      _items = await _apiService.fetchStockItems(_storeId!);
      debugPrint("[StockProvider] Itens carregados: ${_items.length}");
    }, 'fetchStockItems');
    
    // Clear items on error
    if (hasError) {
      _items = [];
    }
  }

  Future<StockItem?> createStockItem(StockItem item) async {
    if (_storeId == null || _storeId! <= 0) {
      setError('ID da loja inválido.', 'createStockItem');
      return null;
    }
    
    return await handleAsyncOperation(() async {
      final newItem = await _apiService.createStockItem(_storeId!, item);
      _items.add(newItem);
      debugPrint("[StockProvider] Item criado: ${newItem.name} (ID: ${newItem.id})");
      return newItem;
    }, 'createStockItem');
  }

  Future<StockItem?> updateStockItem(int itemId, StockItem item) async {
    if (_storeId == null || _storeId! <= 0) {
      setError('ID da loja inválido.', 'updateStockItem');
      return null;
    }
    
    return await handleAsyncOperation(() async {
      final updatedItem = await _apiService.updateStockItem(_storeId!, itemId, item);
      final index = _items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
      }
      debugPrint("[StockProvider] Item atualizado: ${updatedItem.name} (ID: $itemId)");
      return updatedItem;
    }, 'updateStockItem');
  }

  Future<void> deleteStockItem(int itemId) async {
    if (_storeId == null || _storeId! <= 0) {
      setError('ID da loja inválido.', 'deleteStockItem');
      return;
    }
    
    await handleAsyncOperation(() async {
      await _apiService.deleteStockItem(_storeId!, itemId);
      _items.removeWhere((i) => i.id == itemId);
      debugPrint("[StockProvider] Item excluído (ID: $itemId)");
    }, 'deleteStockItem');
  }
}
