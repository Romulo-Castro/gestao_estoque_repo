// lib/services/bulk_import_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import '../models/import_result.dart';
import '../models/stock_item.dart';
import '../services/api_service.dart';

class BulkImportService {
  final ApiService _apiService = ApiService();

  /// Importa mercadorias de um arquivo Excel (.xlsx)
  Future<ImportResult> importFromExcel(File file, int storeId) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      if (excel.tables.isEmpty) {
        return ImportResult(
          totalRows: 0,
          successCount: 0,
          errorCount: 1,
          errors: ['Arquivo Excel não contém planilhas válidas'],
          warnings: [],
        );
      }

      // Pega a primeira planilha
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        return ImportResult(
          totalRows: 0,
          successCount: 0,
          errorCount: 1,
          errors: ['Planilha está vazia'],
          warnings: [],
        );
      }

      return await _processRows(sheet.rows, storeId);
    } catch (e) {
      return ImportResult(
        totalRows: 0,
        successCount: 0,
        errorCount: 1,
        errors: ['Erro ao ler arquivo Excel: $e'],
        warnings: [],
      );
    }
  }

  /// Importa mercadorias de um arquivo CSV
  Future<ImportResult> importFromCsv(File file, int storeId) async {
    try {
      final content = await file.readAsString();
      final List<List<dynamic>> rows = const CsvToListConverter().convert(content);
      
      if (rows.isEmpty) {
        return ImportResult(
          totalRows: 0,
          successCount: 0,
          errorCount: 1,
          errors: ['Arquivo CSV está vazio'],
          warnings: [],
        );
      }

      return await _processRows(rows, storeId);
    } catch (e) {
      return ImportResult(
        totalRows: 0,
        successCount: 0,
        errorCount: 1,
        errors: ['Erro ao ler arquivo CSV: $e'],
        warnings: [],
      );
    }
  }

  /// Processa as linhas do arquivo importado
  Future<ImportResult> _processRows(List<List<dynamic>> rows, int storeId) async {
    final List<String> errors = [];
    final List<String> warnings = [];
    int successCount = 0;
    int errorCount = 0;

    // Skip header row (primeira linha)
    final dataRows = rows.skip(1).toList();
    
    for (int i = 0; i < dataRows.length; i++) {
      final rowIndex = i + 2; // +2 porque pulamos header e index começa em 0
      final row = dataRows[i];
      
      try {
        final merchandise = _parseRowToMerchandise(row, rowIndex);
        if (merchandise == null) {
          errorCount++;
          continue;
        }        // Cria o item no estoque
        final now = DateTime.now().toIso8601String();
        final stockItem = StockItem(
          id: 0, // Será definido pelo backend
          name: merchandise.name,
          quantity: merchandise.quantity,
          storeId: storeId,
          properties: merchandise.toStockItemProperties(),
          createdAt: now,
          updatedAt: now,
        );

        await _apiService.createStockItem(storeId, stockItem);
        successCount++;
        
      } catch (e) {
        errorCount++;
        errors.add('Linha $rowIndex: Erro ao importar - $e');
      }
    }

    return ImportResult(
      totalRows: dataRows.length,
      successCount: successCount,
      errorCount: errorCount,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Converte uma linha do arquivo em dados de mercadoria
  ImportMerchandiseData? _parseRowToMerchandise(List<dynamic> row, int rowIndex) {
    if (row.isEmpty) return null;

    try {
      // Formato esperado das colunas:
      // 0: Nome, 1: Quantidade, 2: Código de Barras, 3: Categoria, 4: Descrição,
      // 5: Preço de Custo, 6: Preço de Venda, 7: Unidade, 8: Fornecedor, 9: Localização, 10: Observações

      final name = _getCellValue(row, 0)?.toString().trim();
      if (name == null || name.isEmpty) {
        throw Exception('Nome é obrigatório');
      }

      final quantityStr = _getCellValue(row, 1)?.toString().trim();
      if (quantityStr == null || quantityStr.isEmpty) {
        throw Exception('Quantidade é obrigatória');
      }

      final quantity = double.tryParse(quantityStr);
      if (quantity == null || quantity < 0) {
        throw Exception('Quantidade deve ser um número válido >= 0');
      }

      return ImportMerchandiseData(
        name: name,
        quantity: quantity,
        barcode: _getCellValue(row, 2)?.toString().trim(),
        category: _getCellValue(row, 3)?.toString().trim(),
        description: _getCellValue(row, 4)?.toString().trim(),
        costPrice: _parseDouble(_getCellValue(row, 5)),
        salePrice: _parseDouble(_getCellValue(row, 6)),
        unit: _getCellValue(row, 7)?.toString().trim(),
        supplier: _getCellValue(row, 8)?.toString().trim(),
        location: _getCellValue(row, 9)?.toString().trim(),
        notes: _getCellValue(row, 10)?.toString().trim(),
      );
    } catch (e) {
      throw Exception('Linha $rowIndex: $e');
    }
  }

  /// Obtém valor de uma célula tratando índices fora do range
  dynamic _getCellValue(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    final value = row[index];
    if (value == null) return null;
    
    // Se for uma célula do Excel
    if (value.runtimeType.toString().contains('Cell')) {
      return (value as dynamic).value;
    }
    
    return value;
  }

  /// Converte valor para double
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    
    // Remove caracteres de formatação de moeda
    final cleanStr = str.replaceAll(RegExp(r'[R$\s.,]'), '').replaceAll(',', '.');
    return double.tryParse(cleanStr);
  }

  /// Gera template Excel para importação
  String getImportTemplateDescription() {
    return '''
FORMATO DO ARQUIVO DE IMPORTAÇÃO

O arquivo deve conter as seguintes colunas (nesta ordem):

1. Nome* (obrigatório) - Nome da mercadoria
2. Quantidade* (obrigatório) - Quantidade em estoque
3. Código de Barras - Código de barras (opcional)
4. Categoria - Categoria do produto (opcional)
5. Descrição - Descrição detalhada (opcional)
6. Preço de Custo - Preço de custo (opcional)
7. Preço de Venda - Preço de venda (opcional)
8. Unidade - Unidade de medida (opcional)
9. Fornecedor - Nome do fornecedor (opcional)
10. Localização - Localização no estoque (opcional)
11. Observações - Observações gerais (opcional)

EXEMPLO DE ARQUIVO CSV:
Nome,Quantidade,Código de Barras,Categoria,Descrição,Preço de Custo,Preço de Venda,Unidade,Fornecedor,Localização,Observações
Arroz Tipo 1,100,1234567890123,Alimentos,Arroz branco tipo 1,2.50,4.00,KG,Fornecedor A,Estoque A,Produto premium
Feijão Preto,50,9876543210987,Alimentos,Feijão preto premium,3.00,5.50,KG,Fornecedor B,Estoque A,Grão selecionado
Açúcar Cristal,75,,Alimentos,Açúcar cristal refinado,1.80,3.20,KG,Fornecedor A,Estoque B,

NOTAS IMPORTANTES:
- A primeira linha deve conter exatamente os cabeçalhos mostrados acima
- Campos marcados com * são obrigatórios
- Use vírgulas para separar os campos no CSV
- Para Excel (.xlsx), as colunas devem estar na mesma ordem
- Preços devem usar ponto (.) como separador decimal
- Se um campo opcional estiver vazio, deixe-o em branco mas mantenha as vírgulas
''';
  }

  /// Gera conteúdo de exemplo para template CSV
  String generateSampleCsvContent() {
    return '''Nome,Quantidade,Código de Barras,Categoria,Descrição,Preço de Custo,Preço de Venda,Unidade,Fornecedor,Localização,Observações
Arroz Tipo 1,100,1234567890123,Alimentos,Arroz branco tipo 1,2.50,4.00,KG,Fornecedor A,Estoque A,Produto premium
Feijão Preto,50,9876543210987,Alimentos,Feijão preto premium,3.00,5.50,KG,Fornecedor B,Estoque A,Grão selecionado
Açúcar Cristal,75,,Alimentos,Açúcar cristal refinado,1.80,3.20,KG,Fornecedor A,Estoque B,
Óleo de Soja,30,5555666677778,Alimentos,Óleo de soja refinado,4.50,7.90,LT,Fornecedor C,Estoque A,Embalagem 900ml
Macarrão Espaguete,25,1111222233334,Alimentos,Macarrão espaguete premium,1.20,2.80,PCT,Fornecedor A,Estoque B,Pacote 500g''';
  }
}
