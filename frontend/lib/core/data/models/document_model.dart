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
    // Map backend fields to frontend fields
    String mappedType = json['type'] ?? 'unknown';
    if (mappedType == 'sale') {
      mappedType = 'saida';
    } else if (mappedType == 'purchase') {
      mappedType = 'entrada';
    }
    
    return DocumentModel(
      id: json['id'],
      number: json['number'] ?? json['id']?.toString() ?? '',
      type: mappedType,
      description: json['description'] ?? json['notes'] ?? '',
      totalValue: (json['total_value'] ?? json['total_amount'] ?? 0.0).toDouble(),
      date: json['date'] ?? json['document_date'] ?? '',
      status: json['status'] ?? 'ATIVO',
      storeId: json['store_id'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => DocumentItemModel.fromJson(item))
              .toList() ??
          [],
    );
  }
  Map<String, dynamic> toJson() {
    // Map frontend fields to backend fields
    String mappedType = type;
    if (type == 'saida') {
      mappedType = 'sale';
    } else if (type == 'entrada') {
      mappedType = 'purchase';
    }
    
    return {
      'id': id,
      'number': number,
      'type': mappedType,
      'description': description,
      'notes': description, // Backend uses 'notes' field
      'total_value': totalValue,
      'total_amount': totalValue, // Backend uses 'total_amount' field
      'date': date,
      'document_date': date, // Backend uses 'document_date' field
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

  /// copyWith method for immutable updates
  DocumentModel copyWith({
    int? id,
    String? number,
    String? type,
    String? description,
    double? totalValue,
    String? date,
    String? status,
    int? storeId,
    List<DocumentItemModel>? items,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      number: number ?? this.number,
      type: type ?? this.type,
      description: description ?? this.description,
      totalValue: totalValue ?? this.totalValue,
      date: date ?? this.date,
      status: status ?? this.status,
      storeId: storeId ?? this.storeId,
      items: items ?? this.items,
    );
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
      stockItemId: json['stock_item_id'] ?? json['itemId'], // Also check for 'itemId'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'unit_value': unitValue,
      'total_value': totalValue,
      'description': description,
      'itemId': stockItemId, // Changed from 'stock_item_id' to 'itemId'
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
