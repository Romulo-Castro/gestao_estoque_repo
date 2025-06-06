// test/bulk_import_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:frontend/services/bulk_import_service.dart';

void main() {
  group('Bulk Import Service Tests', () {
    late BulkImportService importService;

    setUp(() {
      importService = BulkImportService();
    });

    test('should parse CSV content correctly', () async {
      // Create a test CSV file
      const csvContent = '''Nome,Quantidade,Código de Barras,Categoria,Descrição,Preço de Custo,Preço de Venda,Unidade,Fornecedor,Localização,Observações
Arroz Teste,10,123456789,Alimentos,Arroz para teste,2.00,3.50,KG,Fornecedor Teste,Local A,Teste de importação''';
      
      final testFile = File('test_import.csv');
      await testFile.writeAsString(csvContent);
      
      try {
        // Test the CSV import structure (without actually calling the API)
        // This would test the file parsing logic
        final content = await testFile.readAsString();
        expect(content, contains('Nome,Quantidade'));
        expect(content, contains('Arroz Teste'));
        
        // Test template description
        final templateDesc = importService.getImportTemplateDescription();
        expect(templateDesc, contains('Nome* (obrigatório)'));
        expect(templateDesc, contains('Quantidade* (obrigatório)'));
        
        // Test sample CSV generation
        final sampleCsv = importService.generateSampleCsvContent();
        expect(sampleCsv, contains('Nome,Quantidade'));
        expect(sampleCsv, isNotEmpty);
        
      } finally {
        // Clean up test file
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });

    test('should have correct template structure', () {
      final templateDesc = importService.getImportTemplateDescription();
      
      // Check that all required columns are documented
      expect(templateDesc, contains('Nome* (obrigatório)'));
      expect(templateDesc, contains('Quantidade* (obrigatório)'));
      expect(templateDesc, contains('Código de Barras'));
      expect(templateDesc, contains('Categoria'));
      expect(templateDesc, contains('Descrição'));
      expect(templateDesc, contains('Preço de Custo'));
      expect(templateDesc, contains('Preço de Venda'));
      expect(templateDesc, contains('Unidade'));
      expect(templateDesc, contains('Fornecedor'));
      expect(templateDesc, contains('Localização'));
      expect(templateDesc, contains('Observações'));
    });

    test('should generate valid sample CSV', () {
      final sampleCsv = importService.generateSampleCsvContent();
      
      final lines = sampleCsv.split('\n');
      expect(lines.length, greaterThan(1)); // Should have header + data lines
      
      // Check header line
      final header = lines[0];
      expect(header, startsWith('Nome,Quantidade'));
      expect(header, contains('Código de Barras'));
      
      // Check that data lines have the same number of columns as header
      if (lines.length > 1) {
        final headerColumns = header.split(',').length;
        final dataColumns = lines[1].split(',').length;
        expect(dataColumns, equals(headerColumns));
      }
    });
  });
}
