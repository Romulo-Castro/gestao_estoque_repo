// Domain entity for Document - Clean Architecture
import 'package:equatable/equatable.dart';

enum DocumentType { entrada, saida, unknown }

class DocumentEntity extends Equatable {
  final int? id;
  final String number;
  final DocumentType type;
  final String description;
  final double totalValue;
  final DateTime date;
  final int storeId;
  final List<DocumentItemEntity> items;

  const DocumentEntity({
    this.id,
    required this.number,
    required this.type,
    required this.description,
    required this.totalValue,
    required this.date,
    required this.storeId,
    required this.items,
  });

  @override
  List<Object?> get props => [
        id,
        number,
        type,
        description,
        totalValue,
        date,
        storeId,
        items,
      ];

  DocumentEntity copyWith({
    int? id,
    String? number,
    DocumentType? type,
    String? description,
    double? totalValue,
    DateTime? date,
    int? storeId,
    List<DocumentItemEntity>? items,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      number: number ?? this.number,
      type: type ?? this.type,
      description: description ?? this.description,
      totalValue: totalValue ?? this.totalValue,
      date: date ?? this.date,
      storeId: storeId ?? this.storeId,
      items: items ?? this.items,
    );
  }

  bool get isInflow => type == DocumentType.entrada;
  bool get isOutflow => type == DocumentType.saida;
}

class DocumentItemEntity extends Equatable {
  final int? id;
  final int quantity;
  final double unitValue;
  final double totalValue;
  final String description;
  final int? stockItemId;

  const DocumentItemEntity({
    this.id,
    required this.quantity,
    required this.unitValue,
    required this.totalValue,
    required this.description,
    this.stockItemId,
  });

  @override
  List<Object?> get props => [
        id,
        quantity,
        unitValue,
        totalValue,
        description,
        stockItemId,
      ];

  DocumentItemEntity copyWith({
    int? id,
    int? quantity,
    double? unitValue,
    double? totalValue,
    String? description,
    int? stockItemId,
  }) {
    return DocumentItemEntity(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      unitValue: unitValue ?? this.unitValue,
      totalValue: totalValue ?? this.totalValue,
      description: description ?? this.description,
      stockItemId: stockItemId ?? this.stockItemId,
    );
  }
}
