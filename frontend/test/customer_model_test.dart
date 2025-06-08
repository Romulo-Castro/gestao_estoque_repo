import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/data/models/customer_model.dart';

void main() {
  group('Customer Model Tests', () {
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
      expect(() => Customer.fromJson(jsonWithNulls), returnsNormally);
      
      final customer = Customer.fromJson(jsonWithNulls);
      expect(customer.name, equals(''));
      expect(customer.email, isNull);
      expect(customer.phone, isNull);
      expect(customer.address, isNull);
      expect(customer.notes, isNull);
      expect(customer.createdAt, equals(''));
      expect(customer.updatedAt, equals(''));
    });

    test('should handle valid JSON data correctly', () {
      final Map<String, dynamic> validJson = {
        'id': 1,
        'store_id': 1,
        'name': 'Test Customer',
        'email': 'test@customer.com',
        'phone': '123456789',
        'address': 'Test Address',
        'notes': 'Test Notes',
        'created_at': '2023-01-01T00:00:00Z',
        'updated_at': '2023-01-01T00:00:00Z',
      };

      final customer = Customer.fromJson(validJson);
      expect(customer.name, equals('Test Customer'));
      expect(customer.email, equals('test@customer.com'));
      expect(customer.phone, equals('123456789'));
      expect(customer.address, equals('Test Address'));
      expect(customer.notes, equals('Test Notes'));
      expect(customer.createdAt, equals('2023-01-01T00:00:00Z'));
      expect(customer.updatedAt, equals('2023-01-01T00:00:00Z'));
    });

    test('should handle mixed null and valid values', () {
      final Map<String, dynamic> mixedJson = {
        'id': 1,
        'store_id': 1,
        'name': 'Test Customer',
        'email': null,
        'phone': '123456789',
        'address': null,
        'notes': 'Some notes',
        'created_at': '2023-01-01T00:00:00Z',
        'updated_at': null,
      };

      final customer = Customer.fromJson(mixedJson);
      expect(customer.name, equals('Test Customer'));
      expect(customer.email, isNull);
      expect(customer.phone, equals('123456789'));
      expect(customer.address, isNull);
      expect(customer.notes, equals('Some notes'));
      expect(customer.createdAt, equals('2023-01-01T00:00:00Z'));
      expect(customer.updatedAt, equals(''));
    });
  });
}
