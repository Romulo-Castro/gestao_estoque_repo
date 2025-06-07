// lib/providers/layout_provider.dart
import 'package:flutter/material.dart';
import '../../../shared/utils/app_prefs.dart';

enum LayoutType {
  list,
  grid,
  card,
}

class LayoutProvider with ChangeNotifier {
  LayoutType _stockLayoutType = LayoutType.list;
  LayoutType _documentLayoutType = LayoutType.list;
  LayoutType _customerLayoutType = LayoutType.list;
  LayoutType _supplierLayoutType = LayoutType.list;
  
  bool _isLoading = false;

  LayoutType get stockLayoutType => _stockLayoutType;
  LayoutType get documentLayoutType => _documentLayoutType;
  LayoutType get customerLayoutType => _customerLayoutType;
  LayoutType get supplierLayoutType => _supplierLayoutType;
  bool get isLoading => _isLoading;

  LayoutProvider() {
    _loadLayoutPreferences();
  }

  Future<void> _loadLayoutPreferences() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Carregar preferências de layout
      final stockLayout = await AppPrefs.getString('stockLayoutType') ?? 'list';
      final documentLayout = await AppPrefs.getString('documentLayoutType') ?? 'list';
      final customerLayout = await AppPrefs.getString('customerLayoutType') ?? 'list';
      final supplierLayout = await AppPrefs.getString('supplierLayoutType') ?? 'list';

      _stockLayoutType = _stringToLayoutType(stockLayout);
      _documentLayoutType = _stringToLayoutType(documentLayout);
      _customerLayoutType = _stringToLayoutType(customerLayout);
      _supplierLayoutType = _stringToLayoutType(supplierLayout);

      debugPrint("[LayoutProvider] Preferências carregadas - Stock: $stockLayout, Documents: $documentLayout");
    } catch (e) {
      debugPrint("[LayoutProvider] Erro ao carregar preferências: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  LayoutType _stringToLayoutType(String value) {
    switch (value.toLowerCase()) {
      case 'grid':
        return LayoutType.grid;
      case 'card':
        return LayoutType.card;
      case 'list':
      default:
        return LayoutType.list;
    }
  }

  String _layoutTypeToString(LayoutType type) {
    switch (type) {
      case LayoutType.grid:
        return 'grid';
      case LayoutType.card:
        return 'card';
      case LayoutType.list:
        return 'list';
    }
  }

  Future<void> setStockLayoutType(LayoutType type) async {
    if (_stockLayoutType == type) return;

    _stockLayoutType = type;
    notifyListeners();

    try {
      await AppPrefs.setString('stockLayoutType', _layoutTypeToString(type));
      debugPrint("[LayoutProvider] Layout de produtos atualizado para: ${_layoutTypeToString(type)}");
    } catch (e) {
      debugPrint("[LayoutProvider] Erro ao salvar layout de produtos: $e");
    }
  }

  Future<void> setDocumentLayoutType(LayoutType type) async {
    if (_documentLayoutType == type) return;

    _documentLayoutType = type;
    notifyListeners();

    try {
      await AppPrefs.setString('documentLayoutType', _layoutTypeToString(type));
      debugPrint("[LayoutProvider] Layout de documentos atualizado para: ${_layoutTypeToString(type)}");
    } catch (e) {
      debugPrint("[LayoutProvider] Erro ao salvar layout de documentos: $e");
    }
  }

  Future<void> setCustomerLayoutType(LayoutType type) async {
    if (_customerLayoutType == type) return;

    _customerLayoutType = type;
    notifyListeners();

    try {
      await AppPrefs.setString('customerLayoutType', _layoutTypeToString(type));
      debugPrint("[LayoutProvider] Layout de clientes atualizado para: ${_layoutTypeToString(type)}");
    } catch (e) {
      debugPrint("[LayoutProvider] Erro ao salvar layout de clientes: $e");
    }
  }
  Future<void> setSupplierLayoutType(LayoutType type) async {
    if (_supplierLayoutType == type) return;

    _supplierLayoutType = type;
    notifyListeners();

    try {
      await AppPrefs.setString('supplierLayoutType', _layoutTypeToString(type));
      debugPrint("[LayoutProvider] Layout de fornecedores atualizado para: ${_layoutTypeToString(type)}");
    } catch (e) {
      debugPrint("[LayoutProvider] Erro ao salvar layout de fornecedores: $e");
    }
  }

  // Toggle methods for cycling through layout types
  Future<void> toggleStockLayout() async {
    final nextType = _getNextLayoutType(_stockLayoutType);
    await setStockLayoutType(nextType);
  }

  Future<void> toggleDocumentLayout() async {
    final nextType = _getNextLayoutType(_documentLayoutType);
    await setDocumentLayoutType(nextType);
  }

  Future<void> toggleCustomerLayout() async {
    final nextType = _getNextLayoutType(_customerLayoutType);
    await setCustomerLayoutType(nextType);
  }

  Future<void> toggleSupplierLayout() async {
    final nextType = _getNextLayoutType(_supplierLayoutType);
    await setSupplierLayoutType(nextType);
  }

  LayoutType _getNextLayoutType(LayoutType current) {
    switch (current) {
      case LayoutType.list:
        return LayoutType.grid;
      case LayoutType.grid:
        return LayoutType.card;
      case LayoutType.card:
        return LayoutType.list;
    }
  }

  String getLayoutDisplayName(LayoutType type) {
    switch (type) {
      case LayoutType.list:
        return 'Lista';
      case LayoutType.grid:
        return 'Grade';
      case LayoutType.card:
        return 'Cartões';
    }
  }
  IconData getLayoutIcon(LayoutType type) {
    switch (type) {
      case LayoutType.list:
        return Icons.view_list;
      case LayoutType.grid:
        return Icons.view_module;
      case LayoutType.card:
        return Icons.view_agenda;
    }
  }
}

// Extension methods for LayoutType
extension LayoutTypeExtension on LayoutType {
  String get displayName {
    switch (this) {
      case LayoutType.list:
        return 'Lista';
      case LayoutType.grid:
        return 'Grade';
      case LayoutType.card:
        return 'Cartões';
    }
  }

  IconData get icon {
    switch (this) {
      case LayoutType.list:
        return Icons.view_list;
      case LayoutType.grid:
        return Icons.view_module;
      case LayoutType.card:
        return Icons.view_agenda;
    }
  }
}
