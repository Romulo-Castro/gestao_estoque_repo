// lib/core/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int? id;
  final String email;
  final String name;
  final String? role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    this.id,
    required this.email,
    required this.name,
    this.role,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        isActive,
        createdAt,
        updatedAt,
      ];
}
