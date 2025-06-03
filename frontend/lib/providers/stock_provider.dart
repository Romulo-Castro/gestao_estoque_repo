// frontend/lib/providers/stock_provider.dart
import "package:flutter/foundation.dart";
import "/models/stock_item.dart";
import "/services/api_service.dart";

class StockProvider with ChangeNotifier {
  final ApiService _apiService;
  int? _storeId;

  List<StockItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<StockItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    debugPrint("StockProvider Error (Store: $_storeId): $errorMsg");
  }

  Future<void> fetchStockItems() async {
    if (_storeId == null || _storeId! <= 0) {
      _setError("ID da loja inválido para buscar itens.");
      return;
    }
    _setLoading(true);
    try {
      _items = await _apiService.fetchStockItems(_storeId!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _items = [];
    }
  }

  Future<StockItem> createStockItem(StockItem item) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    _setLoading(true);
    try {
      final newItem = await _apiService.createStockItem(_storeId!, item);
      _items.add(newItem);
      _isLoading = false;
      notifyListeners();
      return newItem;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<StockItem> updateStockItem(int itemId, StockItem item) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    _setLoading(true);
    try {
      final updatedItem = await _apiService.updateStockItem(_storeId!, itemId, item);
      final index = _items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
      }
      _isLoading = false;
      notifyListeners();
      return updatedItem;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> deleteStockItem(int itemId) async {
    if (_storeId == null || _storeId! <= 0) throw Exception("ID da loja inválido.");
    _setLoading(true);
    try {
      await _apiService.deleteStockItem(_storeId!, itemId);
      _items.removeWhere((i) => i.id == itemId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }
}
