// lib/providers/store_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/models/store_model.dart';
import '../../data/datasources/api_service.dart';
import '../../../shared/utils/app_prefs.dart';
import '../../../shared/utils/error_handler.dart';

class StoreProvider with ChangeNotifier, ErrorHandlingMixin {
  final ApiService _apiService = ApiService();
  List<Store> _stores = [];
  Store? _selectedStore;
  bool _hasFetchedStores = false; // Flag para saber se já buscou lojas

  List<Store> get stores => _stores;
  Store? get selectedStore => _selectedStore;
  int? get selectedStoreId => _selectedStore?.id;
  // Novo getter para indicar se buscou e não encontrou lojas
  bool get hasNoStores => _hasFetchedStores && _stores.isEmpty && !isLoading && !hasError;

  StoreProvider() {
    debugPrint("StoreProvider inicializado.");
    // Não busca nada aqui, espera o token
  }

  // Chamado pelo ProxyProvider
  void updateAuthToken(String? authToken) {
    if (authToken != null) {
      debugPrint("[StoreProvider] updateAuthToken: Token recebido.");
      _apiService.setAuthToken(authToken);
      
      // Don't automatically fetch stores immediately - let the UI trigger it
      // This prevents issues with invalid tokens on app startup
      debugPrint("[StoreProvider] Token atualizado, aguardando comando para buscar lojas.");
    } else {
      // Usuário deslogou (authToken é null)
      bool changed = false;
      if (_stores.isNotEmpty) { _stores = []; changed = true; }
      if (_selectedStore != null) { _selectedStore = null; changed = true; }
      if (hasError) { clearError(); changed = true; }
      if (isLoading) { setLoading(false); changed = true; }
      if (_hasFetchedStores) { _hasFetchedStores = false; changed = true; } // Reseta flag

      // Só notifica se algo mudou
      if (changed) {
        debugPrint("[StoreProvider] Dados limpos devido ao logout.");
        notifyListeners();
      } else {
        debugPrint("[StoreProvider] Logout, mas nenhum estado interno precisou ser alterado.");
      }
    }
  }

  Future<void> _loadSelectedStorePreference() async {
    final preferredId = await AppPrefs.getSelectedStoreId();
    Store? storeToSelect;

    // Só tenta selecionar se a lista de lojas NÃO estiver vazia
    if (_stores.isNotEmpty) {
       if (preferredId != null) {
          // Tenta encontrar a preferida, senão pega a primeira
          storeToSelect = _stores.firstWhere((s) => s.id == preferredId, orElse: () => _stores.first);
       } else {
          // Nenhuma preferência, seleciona a primeira
          storeToSelect = _stores.first;
       }
    }
    
    // Só altera se realmente mudou (evita notificações desnecessárias)
    if (_selectedStore?.id != storeToSelect?.id) {
      _selectedStore = storeToSelect;
      debugPrint("StoreProvider: Loja selecionada (preferência): ${storeToSelect?.name} (ID: ${storeToSelect?.id})");
      notifyListeners();
    }
  }

  Future<void> fetchStores() async {
    if (_apiService.token == null) {
        debugPrint("StoreProvider: fetchStores chamado sem token, ignorando.");
        return; // Sai se não autenticado
    }
    
    await handleAsyncOperation(() async {
      _stores = await _apiService.fetchUserStores();
      _hasFetchedStores = true; // Marca que a busca foi concluída (com ou sem sucesso na lista)
      debugPrint("StoreProvider: Lojas carregadas: ${_stores.length}");
      // Atualiza a seleção após carregar (já notifica se mudar)
      await _loadSelectedStorePreference();
    }, 'fetchStores');
    
    // In case of error, clear stores and selection
    if (hasError) {
      _stores = [];
      _selectedStore = null;
      
      // Check if it's an authentication error and handle it appropriately
      if (ErrorHandler.isAuthError(error)) {
        debugPrint("StoreProvider: Erro de autenticação detectado durante fetchStores: $error");
        // Don't trigger logout here as it could cause circular dependencies
        // The AuthProvider should handle this when it detects auth errors
      }
    }
  }

  Future<void> selectStore(Store store) async {
    if (_selectedStore?.id == store.id) return;
    _selectedStore = store;
    await AppPrefs.setSelectedStoreId(store.id);
    debugPrint("StoreProvider: Loja selecionada manualmente: ${store.name} (ID: ${store.id})");
    notifyListeners();
  }

  /// Seleciona todas as lojas (view agregada)
  Future<void> selectAllStores() async {
    _selectedStore = null;
    await AppPrefs.setSelectedStoreId(null);
    notifyListeners();
    debugPrint("StoreProvider: Todas as lojas selecionadas.");
  }
    Future<Store?> createStore(String name, String? address) async {
    if (_apiService.token == null) {
      setError('Usuário não autenticado', 'createStore');
      return null;
    }
      return await handleAsyncOperation(() async {
      final newStore = await _apiService.createStore(name, address);
      _stores.add(newStore);
      
      // Se não há loja selecionada, seleciona a nova
      if (_selectedStore == null) {
        await selectStore(newStore);
      }
      
      debugPrint("StoreProvider: Nova loja criada: ${newStore.name} (ID: ${newStore.id})");
      return newStore;
    }, 'createStore');
  }

  Future<Store?> updateStore(int storeId, String name, String? address) async {
    if (_apiService.token == null) {
      setError('Usuário não autenticado', 'updateStore');
      return null;
    }
    
    return await handleAsyncOperation(() async {
      final updatedStore = await _apiService.updateStore(storeId, name, address);
      
      // Atualiza na lista
      final index = _stores.indexWhere((s) => s.id == storeId);
      if (index != -1) _stores[index] = updatedStore;
      if (_selectedStore?.id == storeId) _selectedStore = updatedStore;
      
      debugPrint("StoreProvider: Loja atualizada: ${updatedStore.name} (ID: $storeId)");
      return updatedStore;
    }, 'updateStore');
  }

  Future<void> deleteStore(int storeId) async {
    if (_apiService.token == null) {
      setError('Usuário não autenticado', 'deleteStore');
      return;
    }
    
    await handleAsyncOperation(() async {
      await _apiService.deleteStore(storeId);
      _stores.removeWhere((s) => s.id == storeId);

      // Se a excluída era a selecionada, recarrega a preferência/seleciona outra
      if (_selectedStore?.id == storeId) {
        debugPrint("StoreProvider: Loja selecionada ($storeId) excluída. Recarregando seleção...");
        await _loadSelectedStorePreference(); // Tenta selecionar outra
      }
      debugPrint("StoreProvider: Loja ($storeId) excluída.");
    }, 'deleteStore');
  }
}