// lib/core/domain/entities/stock_item_entity.dart
import 'package:equatable/equatable.dart';

class StockItemEntity extends Equatable {
  final int? id;
  final String code;
  final String description;
  final double currentStock;
  final double unitValue;
  final String? unit;
  final int? itemGroupId;
  final String? itemGroupName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StockItemEntity({
    this.id,
    required this.code,
    required this.description,
    this.currentStock = 0.0,
    this.unitValue = 0.0,
    this.unit,
    this.itemGroupId,
    this.itemGroupName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        code,
        description,
        currentStock,
        unitValue,
        unit,
        itemGroupId,
        itemGroupName,
        isActive,
        createdAt,
        updatedAt,
      ];
}
