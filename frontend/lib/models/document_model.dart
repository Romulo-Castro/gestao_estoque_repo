// frontend/lib/models/document_model.dart
import "package:flutter/foundation.dart";
// Importar o modelo do item

// Enum para tipos de documento (melhor que strings soltas)
enum DocumentType {
  entrada,
  saida,
  transferencia,
  ajuste,
  ajusteEntrada,
  ajusteSaida,
  unknown;

  static DocumentType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ENTRADA':
        return DocumentType.entrada;
      case 'SAIDA':
        return DocumentType.saida;
      case 'TRANSFERENCIA':
        return DocumentType.transferencia;
      case 'AJUSTE':
        return DocumentType.ajuste;
      case 'AJUSTE_ENTRADA':
        return DocumentType.ajusteEntrada;
      case 'AJUSTE_SAIDA':
        return DocumentType.ajusteSaida;
      default:
        return DocumentType.unknown;
    }
  }

  String toJson() {
    switch (this) {
      case DocumentType.entrada:
        return 'ENTRADA';
      case DocumentType.saida:
        return 'SAIDA';
      case DocumentType.transferencia:
        return 'TRANSFERENCIA';
      case DocumentType.ajuste:
        return 'AJUSTE';
      case DocumentType.ajusteEntrada:
        return 'AJUSTE_ENTRADA';
      case DocumentType.ajusteSaida:
        return 'AJUSTE_SAIDA';
      case DocumentType.unknown:
        return 'UNKNOWN';
    }
  }
}

String documentTypeToString(DocumentType type) {
  switch (type) {
    case DocumentType.entrada:
      return "ENTRADA";
    case DocumentType.saida:
      return "SAIDA";
    case DocumentType.transferencia:
      return "TRANSFERENCIA";
    case DocumentType.ajuste:
      return "AJUSTE";
    case DocumentType.ajusteEntrada:
      return "AJUSTE_ENTRADA";
    case DocumentType.ajusteSaida:
      return "AJUSTE_SAIDA";
    default:
      return "UNKNOWN";
  }
}

DocumentType stringToDocumentType(String? typeStr) {
  switch (typeStr?.toUpperCase()) {
    case "ENTRADA":
      return DocumentType.entrada;
    case "SAIDA":
      return DocumentType.saida;
    case "TRANSFERENCIA":
      return DocumentType.transferencia;
    case "AJUSTE":
      return DocumentType.ajuste;
    case "AJUSTE_ENTRADA":
      return DocumentType.ajusteEntrada;
    case "AJUSTE_SAIDA":
      return DocumentType.ajusteSaida;
    default:
      debugPrint("Tipo de documento desconhecido recebido: $typeStr");
      return DocumentType.unknown; // Ou um valor padrão mais apropriado
  }
}

class DocumentItem {
  final String id;
  final String name;
  final double quantity;
  final double price;
  final String unit;
  final String? notes;

  DocumentItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.unit,
    this.notes,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'unit': unit,
      'notes': notes,
    };
  }
}

@immutable
class Document {
  final String id;
  final String number;
  final DocumentType type;
  final String date;
  final String? reference;
  final String? notes;
  final List<DocumentItem> items;
  final String? customerId;
  final String? supplierId;
  final String? sourceWarehouseId;
  final String? destinationWarehouseId;
  final String status;
  final String createdAt;
  final String updatedAt;

  const Document({
    required this.id,
    required this.number,
    required this.type,
    required this.date,
    this.reference,
    this.notes,
    required this.items,
    this.customerId,
    this.supplierId,
    this.sourceWarehouseId,
    this.destinationWarehouseId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: (json['id'] ?? '').toString(),
      number: (json['number'] ?? json['document_number'] ?? '').toString(),
      type: DocumentType.fromString((json['type'] ?? 'unknown').toString()),
      date: (json['date'] ?? json['document_date'] ?? '').toString(),
      reference: json['reference']?.toString(),
      notes: json['notes']?.toString(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => DocumentItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      customerId: json['customerId']?.toString() ?? json['customer_id']?.toString(),
      supplierId: json['supplierId']?.toString() ?? json['supplier_id']?.toString(),
      sourceWarehouseId: json['sourceWarehouseId']?.toString() ?? json['source_warehouse_id']?.toString(),
      destinationWarehouseId: json['destinationWarehouseId']?.toString() ?? json['destination_warehouse_id']?.toString(),
      status: (json['status'] ?? 'DRAFT').toString(),
      createdAt: (json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()).toString(),
      updatedAt: (json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String()).toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'type': type.toJson(),
      'date': date,
      'reference': reference,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
      'customerId': customerId,
      'supplierId': supplierId,
      'sourceWarehouseId': sourceWarehouseId,
      'destinationWarehouseId': destinationWarehouseId,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Document copyWith({
    String? id,
    String? number,
    DocumentType? type,
    String? date,
    String? reference,
    String? notes,
    List<DocumentItem>? items,
    String? customerId,
    String? supplierId,
    String? sourceWarehouseId,
    String? destinationWarehouseId,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      number: number ?? this.number,
      type: type ?? this.type,
      date: date ?? this.date,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      customerId: customerId ?? this.customerId,
      supplierId: supplierId ?? this.supplierId,
      sourceWarehouseId: sourceWarehouseId ?? this.sourceWarehouseId,
      destinationWarehouseId: destinationWarehouseId ?? this.destinationWarehouseId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

