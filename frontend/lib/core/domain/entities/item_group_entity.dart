// lib/core/domain/entities/item_group_entity.dart
import 'package:equatable/equatable.dart';

class ItemGroupEntity extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ItemGroupEntity({
    this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        isActive,
        createdAt,
        updatedAt,
      ];
}
