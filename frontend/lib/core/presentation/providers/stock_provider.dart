// lib/core/presentation/providers/stock_provider.dart
import "package:flutter/foundation.dart";
import "../../data/models/stock_item.dart";
import "../../data/models/document_model.dart";
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

  /// Atualiza a quantidade de um item específico no estoque local
  /// Este método é usado quando documentos são criados/cancelados
  void updateItemQuantity(int itemId, double newQuantity) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final updatedItem = _items[index].copyWith(quantity: newQuantity);
      _items[index] = updatedItem;
      notifyListeners();
      debugPrint("[StockProvider] Quantidade atualizada para item $itemId: $newQuantity");
    }
  }

  /// Aplica mudanças de estoque baseadas em documentos
  /// Para documentos de entrada: adiciona à quantidade
  /// Para documentos de saída: subtrai da quantidade
  void applyDocumentStockChanges(List<DocumentItemModel> items, String documentType) {
    bool hasChanges = false;
    
    for (final docItem in items) {
      final stockIndex = _items.indexWhere((item) => item.id == docItem.stockItemId);
      if (stockIndex != -1) {
        final currentItem = _items[stockIndex];
        double newQuantity;
        
        if (documentType == 'entrada') {
          // Documentos de entrada aumentam o estoque
          newQuantity = currentItem.quantity + docItem.quantity;
        } else if (documentType == 'saida') {
          // Documentos de saída diminuem o estoque
          newQuantity = (currentItem.quantity - docItem.quantity).clamp(0.0, double.infinity);
        } else {
          continue; // Tipo desconhecido, pula este item
        }
        
        final updatedItem = currentItem.copyWith(quantity: newQuantity);
        _items[stockIndex] = updatedItem;
        hasChanges = true;
        
        debugPrint("[StockProvider] Estoque de '${currentItem.name}' atualizado: ${currentItem.quantity} → $newQuantity ($documentType)");
      }
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Reverte mudanças de estoque quando um documento é cancelado
  void revertDocumentStockChanges(List<DocumentItemModel> items, String documentType) {
    bool hasChanges = false;
    
    for (final docItem in items) {
      final stockIndex = _items.indexWhere((item) => item.id == docItem.stockItemId);
      if (stockIndex != -1) {
        final currentItem = _items[stockIndex];
        double newQuantity;
        
        if (documentType == 'entrada') {
          // Reverter entrada: subtrair do estoque
          newQuantity = (currentItem.quantity - docItem.quantity).clamp(0.0, double.infinity);
        } else if (documentType == 'saida') {
          // Reverter saída: adicionar ao estoque
          newQuantity = currentItem.quantity + docItem.quantity;
        } else {
          continue; // Tipo desconhecido, pula este item
        }
        
        final updatedItem = currentItem.copyWith(quantity: newQuantity);
        _items[stockIndex] = updatedItem;
        hasChanges = true;
        
        debugPrint("[StockProvider] Estoque de '${currentItem.name}' revertido: ${currentItem.quantity} → $newQuantity (cancelar $documentType)");
      }
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Obtém um item de estoque por ID
  StockItem? getItemById(int itemId) {
    try {
      return _items.firstWhere((item) => item.id == itemId);
    } catch (e) {
      debugPrint("[StockProvider] Item com ID $itemId não encontrado");
      return null;
    }
  }

  /// Método apenas para testes - adiciona um item de estoque fictício
  void addTestStockItem(int id, String name, double quantity) {
    final testItem = StockItem(
      id: id,
      storeId: _storeId ?? 1,
      name: name,
      quantity: quantity,
      properties: {},
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    _items.add(testItem);
  }
}
