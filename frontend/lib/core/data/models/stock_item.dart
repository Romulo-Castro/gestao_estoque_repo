// lib/models/stock_item.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';

class StockItem {
  final int id;
  final int storeId;
  String name;
  double quantity;
  int? groupId;
  Map<String, dynamic> properties;
  String? imageUrl;
  final String createdAt;
  final String updatedAt;
  // Adicionando campos necessários para os relatórios
  double? price;
  String? sku;

  StockItem({
    required this.id,
    required this.storeId,
    required this.name,
    required this.quantity,
    required this.properties,
    this.groupId,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.price,
    this.sku,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    // Parse das propriedades JSON (se vier como string do DB)
     Map<String, dynamic> parsedProperties = {};
     if (json['properties'] != null) {
        if (json['properties'] is String) {
           try { parsedProperties = jsonDecode(json['properties']); }
           catch(e) { debugPrint("Erro ao parsear properties (string): ${json['properties']}"); }
        } else if (json['properties'] is Map) {
            // Converte chaves/valores para os tipos corretos se necessário
           parsedProperties = Map<String, dynamic>.from(json['properties']);
        }
     }

    return StockItem(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : json['id'] ?? 0,
      storeId: json['store_id'] is String ? int.tryParse(json['store_id']) ?? 0 : json['store_id'] ?? 0,
      name: json['name'] ?? 'Nome Indisponível',
      // Tenta parsear quantity como double (vem como REAL do SQLite)
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      groupId: json['group_id'] is String ? int.tryParse(json['group_id']) : json['group_id'],
      properties: parsedProperties,
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'] ?? "",
      updatedAt: json['updatedAt'] ?? "",
      // Adicionando campos para os relatórios
      price: (json['price'] as num?)?.toDouble(),
      sku: json['sku'] as String?,
    );
  }

  // Usado para enviar dados para criar/atualizar
   Map<String, dynamic> toJson() {
    return {
      // id e storeId geralmente não são enviados no corpo (vão na URL)
      'name': name,
      'quantity': quantity,
      'group_id': groupId,
      'properties': properties,
      'price': price,
      'sku': sku,
    };
  }

  // copyWith para facilitar updates
  StockItem copyWith({
    int? id,
    int? storeId,
    String? name,
    double? quantity,
    int? groupId,
    Map<String, dynamic>? properties,
    String? imageUrl,
    String? createdAt,
    String? updatedAt,
    double? price,
    String? sku,
  }) {
    return StockItem(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      groupId: groupId ?? this.groupId,
      properties: properties ?? this.properties,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      price: price ?? this.price,
      sku: sku ?? this.sku,
    );
  }
}
