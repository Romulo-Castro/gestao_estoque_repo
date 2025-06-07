// Document Data Model (DTO) - Clean Architecture
import '../../domain/entities/document_entity.dart';

class DocumentModel {
  final int? id;
  final String number;
  final String type;
  final String description;
  final double totalValue;
  final String date;
  final String status;
  final int storeId;
  final List<DocumentItemModel> items;

  const DocumentModel({
    this.id,
    required this.number,
    required this.type,
    required this.description,
    required this.totalValue,
    required this.date,
    required this.status,
    required this.storeId,
    required this.items,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      number: json['number'] ?? '',
      type: json['type'] ?? 'unknown',
      description: json['description'] ?? '',
      totalValue: (json['total_value'] ?? 0.0).toDouble(),
      date: json['date'] ?? '',
      status: json['status'] ?? 'ATIVO',
      storeId: json['store_id'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => DocumentItemModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'type': type,
      'description': description,
      'total_value': totalValue,
      'date': date,
      'status': status,
      'store_id': storeId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  DocumentEntity toEntity() {
    return DocumentEntity(
      id: id,
      number: number,
      type: _parseDocumentType(type),
      description: description,
      totalValue: totalValue,
      date: _parseDate(date),
      status: status,
      storeId: storeId,
      items: items.map((item) => item.toEntity()).toList(),
    );
  }

  factory DocumentModel.fromEntity(DocumentEntity entity) {
    return DocumentModel(
      id: entity.id,
      number: entity.number,
      type: _documentTypeToString(entity.type),
      description: entity.description,
      totalValue: entity.totalValue,
      date: entity.date.toIso8601String(),
      status: entity.status,
      storeId: entity.storeId,
      items: entity.items.map((item) => DocumentItemModel.fromEntity(item)).toList(),
    );
  }

  DocumentType _parseDocumentType(String type) {
    switch (type.toLowerCase()) {
      case 'entrada':
        return DocumentType.entrada;
      case 'saida':
      case 'saída':
        return DocumentType.saida;
      default:
        return DocumentType.unknown;
    }
  }

  static String _documentTypeToString(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return 'entrada';
      case DocumentType.saida:
        return 'saida';
      case DocumentType.unknown:
        return 'unknown';
    }
  }

  DateTime _parseDate(String dateString) {
    try {
      if (dateString.isEmpty) {
        return DateTime.now();
      }
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }
}

class DocumentItemModel {
  final int? id;
  final int quantity;
  final double unitValue;
  final double totalValue;
  final String description;
  final int? stockItemId;

  const DocumentItemModel({
    this.id,
    required this.quantity,
    required this.unitValue,
    required this.totalValue,
    required this.description,
    this.stockItemId,
  });

  factory DocumentItemModel.fromJson(Map<String, dynamic> json) {
    return DocumentItemModel(
      id: json['id'],
      quantity: json['quantity'] ?? 0,
      unitValue: (json['unit_value'] ?? 0.0).toDouble(),
      totalValue: (json['total_value'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      stockItemId: json['stock_item_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'unit_value': unitValue,
      'total_value': totalValue,
      'description': description,
      'stock_item_id': stockItemId,
    };
  }

  DocumentItemEntity toEntity() {
    return DocumentItemEntity(
      id: id,
      quantity: quantity,
      unitValue: unitValue,
      totalValue: totalValue,
      description: description,
      stockItemId: stockItemId,
    );
  }

  factory DocumentItemModel.fromEntity(DocumentItemEntity entity) {
    return DocumentItemModel(
      id: entity.id,
      quantity: entity.quantity,
      unitValue: entity.unitValue,
      totalValue: entity.totalValue,
      description: entity.description,
      stockItemId: entity.stockItemId,
    );
  }
}
