// lib/providers/dashboard_provider.dart
import 'package:flutter/foundation.dart';
import '/services/api_service.dart';
import '/utils/error_handler.dart';

class DashboardStats {
  final int totalProducts;
  final int totalDocuments;
  final int totalCustomers;
  final int totalSuppliers;
  final int totalGroups;
  final double totalStockValue;
  final int lowStockItems;
  final Map<String, int> documentsByType;

  const DashboardStats({
    this.totalProducts = 0,
    this.totalDocuments = 0,
    this.totalCustomers = 0,
    this.totalSuppliers = 0,
    this.totalGroups = 0,
    this.totalStockValue = 0.0,
    this.lowStockItems = 0,
    this.documentsByType = const {},
  });

  DashboardStats copyWith({
    int? totalProducts,
    int? totalDocuments,
    int? totalCustomers,
    int? totalSuppliers,
    int? totalGroups,
    double? totalStockValue,
    int? lowStockItems,
    Map<String, int>? documentsByType,
  }) {
    return DashboardStats(
      totalProducts: totalProducts ?? this.totalProducts,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      totalSuppliers: totalSuppliers ?? this.totalSuppliers,
      totalGroups: totalGroups ?? this.totalGroups,
      totalStockValue: totalStockValue ?? this.totalStockValue,
      lowStockItems: lowStockItems ?? this.lowStockItems,
      documentsByType: documentsByType ?? this.documentsByType,
    );
  }
}

class DashboardProvider with ChangeNotifier, ErrorHandlingMixin {
  final ApiService _apiService = ApiService();
  int? _storeId;
  DashboardStats _stats = const DashboardStats();

  DashboardStats get stats => _stats;

  DashboardProvider() {
    debugPrint("[DashboardProvider] Inicializado.");
  }

  // Método para atualizar o token de autenticação
  void updateAuthToken(String? token) {
    _apiService.setAuthToken(token);
    debugPrint("[DashboardProvider] Token atualizado: ${token != null ? 'presente' : 'nulo'}");
  }

  // Método para definir o ID da loja atual
  void setStoreId(int? storeId) {
    if (_storeId == storeId) return;
    _storeId = storeId;
    _stats = const DashboardStats();
    clearError();
    notifyListeners();
    debugPrint("[DashboardProvider] Store ID definido: $storeId");

    if (storeId != null) {
      fetchDashboardStats();
    }
  }

  /// Buscar estatísticas do dashboard
  Future<void> fetchDashboardStats() async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'fetchDashboardStats');
      return;
    }

    await handleAsyncOperation(() async {
      // Buscar dados paralelamente
      final results = await Future.wait([
        _apiService.fetchStockItems(_storeId!),
        _apiService.fetchDocuments(_storeId!),
        _apiService.fetchCustomers(_storeId!),
        _apiService.fetchSuppliers(_storeId!),
        _apiService.fetchItemGroups(_storeId!),
      ]);

      final products = results[0] as List;
      final documents = results[1] as List;
      final customers = results[2] as List;
      final suppliers = results[3] as List;
      final groups = results[4] as List;

      // Calcular valor total do estoque
      double totalValue = 0.0;
      int lowStockCount = 0;
      for (var product in products) {
        final quantity = (product['quantity'] ?? 0).toDouble();
        final price = (product['price'] ?? 0).toDouble();
        totalValue += quantity * price;
        
        // Contar itens com estoque baixo (menos de 10)
        if (quantity < 10) {
          lowStockCount++;
        }
      }

      // Contar documentos por tipo
      Map<String, int> docsByType = {};
      for (var doc in documents) {
        final type = doc['type'] ?? 'unknown';
        docsByType[type] = (docsByType[type] ?? 0) + 1;
      }

      _stats = DashboardStats(
        totalProducts: products.length,
        totalDocuments: documents.length,
        totalCustomers: customers.length,
        totalSuppliers: suppliers.length,
        totalGroups: groups.length,
        totalStockValue: totalValue,
        lowStockItems: lowStockCount,
        documentsByType: docsByType,
      );

      debugPrint("[DashboardProvider] Estatísticas carregadas: ${_stats.totalProducts} produtos, ${_stats.totalDocuments} documentos");
    }, 'fetchDashboardStats');
  }

  /// Atualizar estatísticas após operação
  void incrementProductCount() {
    _stats = _stats.copyWith(totalProducts: _stats.totalProducts + 1);
    notifyListeners();
  }

  void decrementProductCount() {
    _stats = _stats.copyWith(totalProducts: _stats.totalProducts - 1);
    notifyListeners();
  }

  void incrementDocumentCount() {
    _stats = _stats.copyWith(totalDocuments: _stats.totalDocuments + 1);
    notifyListeners();
  }

  void incrementCustomerCount() {
    _stats = _stats.copyWith(totalCustomers: _stats.totalCustomers + 1);
    notifyListeners();
  }

  void decrementCustomerCount() {
    _stats = _stats.copyWith(totalCustomers: _stats.totalCustomers - 1);
    notifyListeners();
  }

  void incrementSupplierCount() {
    _stats = _stats.copyWith(totalSuppliers: _stats.totalSuppliers + 1);
    notifyListeners();
  }

  void decrementSupplierCount() {
    _stats = _stats.copyWith(totalSuppliers: _stats.totalSuppliers - 1);
    notifyListeners();
  }
}
