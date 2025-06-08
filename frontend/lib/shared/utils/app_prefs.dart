// lib/utils/app_prefs.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Classe utilitária para gerenciar preferências do aplicativo
class AppPrefs {
  // Chaves para preferências
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keySelectedStoreId = 'selected_store_id';
  static const String _keyGroupId = 'group_id';
  static const String _keyUseCardLayout = 'use_card_layout';
  static const String _keyQuantityDecimals = 'quantity_decimals';
  
  // Propriedades de itens
  static const String propName = 'name';
  static const String propQuantity = 'quantity';
  static const String propImage = 'image';
  static const String propCategory = 'category';
  static const String propGroupId = 'groupId';
  static const String propBarcode = 'barcode';
  static const String propDescription = 'description';
  static const String propTags = 'tags';
  static const String propUom = 'uom';
  static const String propMinStock = 'minStock';

  /// Verifica se é o primeiro lançamento do aplicativo
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    // Se a chave não existir, assume que é o primeiro lançamento
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  /// Define que o aplicativo já foi lançado antes
  static Future<void> setFirstLaunchCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, completed);
  }

  /// Salva o ID da loja selecionada
  static Future<void> saveSelectedStoreId(int? storeId) async {
    final prefs = await SharedPreferences.getInstance();
    if (storeId == null) {
      await prefs.remove(_keySelectedStoreId);
    } else {
      await prefs.setInt(_keySelectedStoreId, storeId);
    }
  }

  /// Método compatível com o nome usado em StoreProvider
  static Future<void> setSelectedStoreId(int? storeId) async {
    await saveSelectedStoreId(storeId);
  }

  /// Recupera o ID da loja selecionada
  static Future<int?> getSelectedStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySelectedStoreId);
  }

  /// Salva o ID do grupo selecionado
  static Future<void> saveGroupId(int? groupId) async {
    final prefs = await SharedPreferences.getInstance();
    if (groupId == null) {
      await prefs.remove(_keyGroupId);
    } else {
      await prefs.setInt(_keyGroupId, groupId);
    }
  }

  /// Recupera o ID do grupo selecionado
  static Future<int?> getGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyGroupId);
  }

  /// Salva a preferência de layout em cartões
  static Future<void> setUseCardLayout(bool useCards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseCardLayout, useCards);
  }

  /// Recupera a preferência de layout em cartões
  static Future<bool> getUseCardLayout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseCardLayout) ?? false;
  }

  /// Salva a quantidade de casas decimais para quantidades
  static Future<void> setQuantityDecimals(int decimals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyQuantityDecimals, decimals);
  }

  /// Recupera a quantidade de casas decimais para quantidades
  static Future<int> getQuantityDecimals() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyQuantityDecimals) ?? 0;
  }

  /// Salva as propriedades de item ativas
  static Future<void> setItemProperties(List<String> properties) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('item_properties', properties);
  }

  /// Recupera as propriedades de item ativas
  static Future<List<String>> getItemProperties() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('item_properties') ?? [propName, propQuantity, propImage, propCategory];
  }

  /// Método genérico para salvar um valor booleano
  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Método genérico para recuperar um valor booleano
  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  /// Método genérico para salvar uma string
  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Método genérico para recuperar uma string
  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Método genérico para salvar um inteiro
  static Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  /// Método genérico para recuperar um inteiro
  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  /// Limpa todas as preferências
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> savePreferences({
    required String selectedCompany,
    required String? selectedBranch,
    required String? selectedWarehouse,
    required bool firstLaunch,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_company', selectedCompany);
    await prefs.setString('selected_branch', selectedBranch ?? '');
    await prefs.setString('selected_warehouse', selectedWarehouse ?? '');
    await prefs.setBool('first_launch', firstLaunch);
  }

  static Future<String?> getSelectedCompany() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_company');
  }

  static Future<String?> getSelectedBranch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_branch');
  }

  static Future<String?> getSelectedWarehouse() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_warehouse');
  }
}
