// frontend/lib/providers/item_group_provider.dart
import "package:flutter/widgets.dart";
import "../../data/models/item_group_model.dart";
import "../../data/datasources/api_service.dart";
import "../../../shared/utils/error_handler.dart";

class ItemGroupProvider with ChangeNotifier, ErrorHandlingMixin {
  final ApiService _apiService;
  int? _storeId;

  List<ItemGroup> _groups = [];

  List<ItemGroup> get groups => _groups;

  // Construtor padrão para uso com ProxyProvider
  ItemGroupProvider() : _apiService = ApiService(), _storeId = null;

  // Método para atualizar o token de autenticação
  void updateAuthToken(String? token) {
    _apiService.setAuthToken(token);
    debugPrint("[ItemGroupProvider] Token atualizado: ${token != null ? 'presente' : 'nulo'}");
  }

  // Método para definir o ID da loja atual
  void setStoreId(int? storeId) {
    if (_storeId == storeId) return;
    
    // Only set valid store IDs
    if (storeId != null && storeId > 0) {
      _storeId = storeId;
      // Use postFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchItemGroups();
      });
    } else {
      // Clear store ID and groups when no valid store selected
      _storeId = null;
      _groups = [];
      clearError();
      setLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchItemGroups() async {
    if (_storeId == null || _storeId! <= 0) {
      setError("ID da loja inválido para buscar grupos.", 'fetchItemGroups');
      return;
    }
    
    await handleAsyncOperation(() async {
      _groups = await _apiService.fetchItemGroups(_storeId!);
      debugPrint("[ItemGroupProvider] Grupos carregados: ${_groups.length}");
    }, 'fetchItemGroups');
    
    // Clear groups on error
    if (hasError) {
      _groups = [];
    }
  }

  Future<ItemGroup?> createItemGroup(String name, {String? description, int? parentGroupId}) async {
    if (_storeId == null || _storeId! <= 0) {
      setError('ID da loja inválido.', 'createItemGroup');
      return null;
    }
    
    return await handleAsyncOperation(() async {
      // Criar objeto ItemGroup para passar ao ApiService
      final group = ItemGroup(
        id: 0, // ID será atribuído pelo backend
        storeId: _storeId!,
        name: name,
        description: description,
        createdAt: "",
        updatedAt: "",
      );
      
      final newGroup = await _apiService.createItemGroup(_storeId!, group);
      _groups.add(newGroup);
      debugPrint("[ItemGroupProvider] Grupo criado: ${newGroup.name} (ID: ${newGroup.id})");
      return newGroup;
    }, 'createItemGroup');
  }

  Future<ItemGroup?> updateItemGroup(int groupId, String name, {String? description, int? parentGroupId}) async {
    if (_storeId == null || _storeId! <= 0) {
      setError('ID da loja inválido.', 'updateItemGroup');
      return null;
    }
    
    return await handleAsyncOperation(() async {
      // Encontrar o grupo existente
      final existingGroup = _groups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => throw Exception("Grupo não encontrado"),
      );
      
      // Criar objeto atualizado
      final group = existingGroup.copyWith(
        name: name,
        description: description,
      );
      
      final updatedGroup = await _apiService.updateItemGroup(_storeId!, groupId, group);
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = updatedGroup;
      }
      debugPrint("[ItemGroupProvider] Grupo atualizado: ${updatedGroup.name} (ID: $groupId)");
      return updatedGroup;
    }, 'updateItemGroup');
  }

  Future<void> deleteItemGroup(int groupId) async {
    if (_storeId == null || _storeId! <= 0) {
      setError('ID da loja inválido.', 'deleteItemGroup');
      return;
    }
    
    await handleAsyncOperation(() async {
      await _apiService.deleteItemGroup(_storeId!, groupId);
      _groups.removeWhere((g) => g.id == groupId);
      debugPrint("[ItemGroupProvider] Grupo excluído (ID: $groupId)");
    }, 'deleteItemGroup');
  }
}
