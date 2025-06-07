// lib/core/domain/entities/supplier_entity.dart
import 'package:equatable/equatable.dart';

class SupplierEntity extends Equatable {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? taxId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupplierEntity({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.taxId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        address,
        taxId,
        isActive,
        createdAt,
        updatedAt,
      ];
}
