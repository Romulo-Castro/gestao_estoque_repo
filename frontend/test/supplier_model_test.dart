import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/data/models/supplier_model.dart';

void main() {
  group('Supplier Model Tests', () {
    test('should handle null values in JSON without throwing errors', () {
      // Test data with null values that previously caused errors
      final Map<String, dynamic> jsonWithNulls = {
        'id': 1,
        'store_id': 1,
        'name': null, // This was causing the error
        'email': null,
        'phone': null,
        'address': null,
        'notes': null,
        'created_at': null, // This was also causing errors
        'updated_at': null,
      };

      // This should not throw an error anymore
      expect(() => Supplier.fromJson(jsonWithNulls), returnsNormally);
      
      final supplier = Supplier.fromJson(jsonWithNulls);
      expect(supplier.name, equals(''));
      expect(supplier.email, isNull);
      expect(supplier.phone, isNull);
      expect(supplier.address, isNull);
      expect(supplier.notes, isNull);
      expect(supplier.createdAt, equals(''));
      expect(supplier.updatedAt, equals(''));
    });

    test('should handle valid JSON data correctly', () {
      final Map<String, dynamic> validJson = {
        'id': 1,
        'store_id': 1,
        'name': 'Test Supplier',
        'email': 'test@supplier.com',
        'phone': '123456789',
        'address': 'Test Address',
        'notes': 'Test Notes',
        'created_at': '2023-01-01T00:00:00Z',
        'updated_at': '2023-01-01T00:00:00Z',
      };

      final supplier = Supplier.fromJson(validJson);
      expect(supplier.name, equals('Test Supplier'));
      expect(supplier.email, equals('test@supplier.com'));
      expect(supplier.phone, equals('123456789'));
      expect(supplier.address, equals('Test Address'));
      expect(supplier.notes, equals('Test Notes'));
      expect(supplier.createdAt, equals('2023-01-01T00:00:00Z'));
      expect(supplier.updatedAt, equals('2023-01-01T00:00:00Z'));
    });

    test('should handle mixed null and valid values', () {
      final Map<String, dynamic> mixedJson = {
        'id': 1,
        'store_id': 1,
        'name': 'Test Supplier',
        'email': null,
        'phone': '123456789',
        'address': null,
        'notes': 'Some notes',
        'created_at': '2023-01-01T00:00:00Z',
        'updated_at': null,
      };

      final supplier = Supplier.fromJson(mixedJson);
      expect(supplier.name, equals('Test Supplier'));
      expect(supplier.email, isNull);
      expect(supplier.phone, equals('123456789'));
      expect(supplier.address, isNull);
      expect(supplier.notes, equals('Some notes'));
      expect(supplier.createdAt, equals('2023-01-01T00:00:00Z'));
      expect(supplier.updatedAt, equals(''));
    });
  });
}
