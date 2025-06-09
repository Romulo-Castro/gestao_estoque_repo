// lib/shared/services/bulk_import_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import '../../core/data/models/stock_item.dart';
import '../../core/data/models/import_result.dart';
import '../../core/data/datasources/api_service.dart';
import '../utils/logger.dart';

class BulkImportService {
  final ApiService _apiService; // Modificado para receber ApiService

  // Construtor modificado para aceitar ApiService
  BulkImportService(this._apiService);

  /// Importa mercadorias de um arquivo CSV
  Future<ImportResult> importFromCsv(File file, int storeId) async {
    AppLogger.info('Iniciando importação CSV', 'BulkImportService');
    try {
      final csvString = await file.readAsString();
      if (csvString.trim().isEmpty) {
        return ImportResult(
          totalRows: 0,
          successCount: 0,
          errorCount: 1,
          errors: ['Arquivo CSV está vazio'],
          warnings: [],
        );
      }

      // Normalize line endings to \n before parsing
      final normalizedCsvString = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      final List<List<dynamic>> rows =
          const CsvToListConverter(eol: '\n', fieldDelimiter: ',')
              .convert(normalizedCsvString);

      AppLogger.debug('CSV parsing produced ${rows.length} rows after normalization.', 'BulkImportService');
      if (rows.isNotEmpty) {
        AppLogger.debug('First row content (after normalization): ${rows.first}', 'BulkImportService');
      }

      if (rows.isEmpty || rows.length <= 1) { // Ensure there are data rows beyond a potential header
        AppLogger.warning('CSV has no data rows after normalization. Total rows: ${rows.length}', 'BulkImportService');
        return ImportResult(
            totalRows: 0,
            successCount: 0,
            errorCount: 1,
            errors: ['Arquivo CSV não contém dados (apenas cabeçalho ou vazio)'],
            warnings: []);
      }
      return await _processRows(rows, storeId);
    } catch (e, s) {
      // Assuming AppLogger.error can take an error object and stacktrace
      AppLogger.error('Erro ao importar CSV: $e', 'BulkImportService', e, s);
      return ImportResult(
        totalRows: 0, // Or attempt to count rows if possible before error
        successCount: 0,
        errorCount: 1, // Or more, depending on how row count is determined
        errors: ['Erro ao processar arquivo CSV: $e'],
        warnings: [],
      );
    }
  }

  /// Importa mercadorias de um arquivo Excel (.xlsx)
  Future<ImportResult> importFromExcel(File file, int storeId) async {
    try {
      AppLogger.info('Iniciando importação Excel', 'BulkImportService');
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
      AppLogger.error('Erro ao ler arquivo Excel: $e', 'BulkImportService');
      return ImportResult(
        totalRows: 0,
        successCount: 0,
        errorCount: 1,
        errors: ['Erro ao ler arquivo Excel: $e'],
        warnings: [],
      );
    }
  }

  /// Valida dados do CSV e retorna lista de StockItem (não usado no fluxo atual)
  Future<List<StockItem>> validateCsvData(File file) async {
    try {
      final content = await file.readAsString();
      final List<List<dynamic>> rows = const CsvToListConverter().convert(content);
      
      if (rows.isEmpty) {
        throw Exception('Arquivo CSV está vazio');
      }

      final List<StockItem> items = [];
      final dataRows = rows.skip(1).toList(); // Skip header
      
      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final merchandise = _parseRowToMerchandise(row, i + 2);
        if (merchandise != null) {
          final now = DateTime.now().toIso8601String();
          final stockItem = StockItem(
            id: 0, // Será definido pelo backend
            name: merchandise.name,
            quantity: merchandise.quantity,
            storeId: 0, // Placeholder
            properties: merchandise.toStockItemProperties(),
            createdAt: now,
            updatedAt: now,
          );
          items.add(stockItem);
        }
      }
      
      return items;
    } catch (e) {
      AppLogger.error('Erro na validação CSV: $e', 'BulkImportService');
      rethrow;
    }
  }

  /// Processa dados de importação (não usado no fluxo atual)
  Future<bool> processImportData(List<StockItem> items) async {
    try {
      AppLogger.info('Processando ${items.length} itens', 'BulkImportService');
      // Esta implementação seria para processar dados já validados
      // No fluxo atual, usamos _processRows diretamente
      return true;
    } catch (e) {
      AppLogger.error('Erro no processamento: $e', 'BulkImportService');
      return false;
    }
  }

  /// Importa itens já processados (não usado no fluxo atual)
  Future<ImportResult> importItems(List<StockItem> items) async {
    try {
      int successCount = 0;
      int errorCount = 0;
      final List<String> errors = [];

      for (final item in items) {
        try {
          await _apiService.createStockItem(item.storeId, item);
          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('Erro ao importar ${item.name}: $e');
        }
      }

      return ImportResult(
        totalRows: items.length,
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
        warnings: [],
      );
    } catch (e) {
      AppLogger.error('Erro na importação de itens: $e', 'BulkImportService');
      return ImportResult(
        totalRows: items.length,
        successCount: 0,
        errorCount: items.length,
        errors: ['Erro geral na importação: $e'],
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
        if (merchandise == null) { // Should not happen with current _parseRowToMerchandise logic if row is not empty
          errorCount++;
          errors.add('Linha $rowIndex: Linha vazia ou inválida (retorno nulo do parser)');
          continue;
        }

        // Cria o item no estoque
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

        // NOTE: In a real scenario, ensure ApiService is mocked for unit tests
        // For this specific test ('Import service validates required fields'),
        // this line should not be reached if _parseRowToMerchandise throws.
        await _apiService.createStockItem(storeId, stockItem);
        successCount++;
        AppLogger.debug('Item importado: ${merchandise.name}', 'BulkImportService');
        
      } catch (e) {
        errorCount++;
        String errorMessage = e.toString();
        if (e is Exception) {
          // Remove "Exception: " prefix if present
          errorMessage = errorMessage.replaceFirst(RegExp(r'^Exception: '), '');
        }
        // Ensure the error message from _parseRowToMerchandise (which might already contain "Linha X: ")
        // isn't re-prefixed if it's a direct pass-through.
        // Porém, _parseRowToMerchandise foi alterado para lançar mensagens simples.
        errors.add('Linha $rowIndex: $errorMessage');
        AppLogger.warning('Erro na linha $rowIndex ($errorMessage): $e', 'BulkImportService');
      }
    }

    AppLogger.info('Importação concluída - Sucessos: $successCount, Erros: $errorCount', 'BulkImportService');
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
    // Validate Nome (Column 0)
    final dynamic rawNameValue = _getCellValue(row, 0);
    final String nameString = (rawNameValue?.toString() ?? '').trim();
    if (nameString.isEmpty) {
      throw Exception('Nome é obrigatório');
    }

    // Validate Quantidade (Column 1)
    final dynamic rawQuantityValue = _getCellValue(row, 1);
    final String quantityString = (rawQuantityValue?.toString() ?? '').trim();
    if (quantityString.isEmpty) {
      throw Exception('Quantidade é obrigatória');
    }

    final double? quantity = double.tryParse(quantityString.replaceAll(',', '.'));
    if (quantity == null || quantity < 0) {
      throw Exception('Quantidade deve ser um número válido >= 0. Valor recebido: "$quantityString"');
    }

    return ImportMerchandiseData(
      name: nameString,
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
  }

  /// Obtém valor de uma célula tratando índices fora do range e convertendo para String.
  /// Retorna null se o valor for null ou o índice estiver fora do alcance
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

  /// Gera template para importação
  String getImportTemplateDescription() {
    return '''
FORMATO DO ARQUIVO DE IMPORTAÇÃO

O arquivo deve ser Excel (.xlsx) ou CSV (.csv) com as seguintes colunas (nesta ordem):

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
Macarrão Espaguete,25,1111222233334,Alimentos,Macarrão espaguete premium,1.20,2.80,PCT,Fornecedor A,Estoque B,Pacote 500g
Sabão em Pó,40,2222333344445,Limpeza,Sabão em pó concentrado 1kg,6.80,12.90,PCT,Fornecedor GHI,Estoque C,Fórmula concentrada
Refrigerante Cola,60,3333444455556,Bebidas,Refrigerante cola 2L,3.20,5.80,UN,Fornecedor JKL,Estoque A,Garrafa pet 2L
Papel Higiênico,35,4444555566667,Higiene,Papel higiênico folha dupla c/12,8.50,15.90,PCT,Fornecedor MNO,Estoque C,Pacote com 12 rolos
Leite Integral,80,5555666677778,Laticínios,Leite integral 1L,2.80,4.50,LT,Fornecedor PQR,Estoque B,Caixa tetra pak
Biscoito Salgado,45,6666777788889,Alimentos,Biscoito cream cracker 400g,2.20,3.80,PCT,Fornecedor STU,Estoque A,Pacote 400g''';
  }

  /// Gera um arquivo Excel template com dados de exemplo
  Future<File> generateExcelTemplate() async {
    final excel = Excel.createExcel();
    
    // Remove a planilha padrão
    excel.delete('Sheet1');
    
    // Cria uma nova planilha
    final sheet = excel['Template_Importacao'];
    
    // Define os cabeçalhos
    final headers = [
      'Nome',
      'Quantidade',
      'Código de Barras',
      'Categoria', 
      'Descrição',
      'Preço de Custo',
      'Preço de Venda',
      'Unidade',
      'Fornecedor',
      'Localização',
      'Observações'
    ];
    
    // Adiciona os cabeçalhos na primeira linha
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      // Formata o cabeçalho
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
        horizontalAlign: HorizontalAlign.Center,
      );
    }
    
    // Dados de exemplo
    final sampleData = [
      ['Arroz Tipo 1', 100, '1234567890123', 'Alimentos', 'Arroz branco tipo 1 kg', 2.50, 4.00, 'KG', 'Fornecedor ABC', 'Estoque A', 'Produto premium'],
      ['Feijão Preto', 50, '9876543210987', 'Alimentos', 'Feijão preto premium 1kg', 3.00, 5.50, 'KG', 'Fornecedor XYZ', 'Estoque A', 'Grão selecionado'],
      ['Açúcar Cristal', 75, '', 'Alimentos', 'Açúcar cristal refinado 1kg', 1.80, 3.20, 'KG', 'Fornecedor ABC', 'Estoque B', ''],
      ['Óleo de Soja', 30, '5555666677778', 'Alimentos', 'Óleo de soja refinado 900ml', 4.50, 7.90, 'LT', 'Fornecedor DEF', 'Estoque A', 'Embalagem 900ml'],
      ['Macarrão Espaguete', 25, '1111222233334', 'Alimentos', 'Macarrão espaguete premium 500g', 1.20, 2.80, 'PCT', 'Fornecedor ABC', 'Estoque B', 'Pacote 500g'],
      ['Sabão em Pó', 40, '2222333344445', 'Limpeza', 'Sabão em pó concentrado 1kg', 6.80, 12.90, 'PCT', 'Fornecedor GHI', 'Estoque C', 'Fórmula concentrada'],
      ['Refrigerante Cola', 60, '3333444455556', 'Bebidas', 'Refrigerante cola 2L', 3.20, 5.80, 'UN', 'Fornecedor JKL', 'Estoque A', 'Garrafa pet 2L'],
      ['Papel Higiênico', 35, '4444555566667', 'Higiene', 'Papel higiênico folha dupla c/12', 8.50, 15.90, 'PCT', 'Fornecedor MNO', 'Estoque C', 'Pacote com 12 rolos'],
      ['Leite Integral', 80, '5555666677778', 'Laticínios', 'Leite integral 1L', 2.80, 4.50, 'LT', 'Fornecedor PQR', 'Estoque B', 'Caixa tetra pak'],
      ['Biscoito Salgado', 45, '6666777788889', 'Alimentos', 'Biscoito cream cracker 400g', 2.20, 3.80, 'PCT', 'Fornecedor STU', 'Estoque A', 'Pacote 400g']
    ];
    
    // Adiciona os dados de exemplo
    for (int row = 0; row < sampleData.length; row++) {
      for (int col = 0; col < sampleData[row].length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
        final value = sampleData[row][col];
        
        if (value is String) {
          cell.value = TextCellValue(value);
        } else if (value is int) {
          cell.value = IntCellValue(value);
        } else if (value is double) {
          cell.value = DoubleCellValue(value);
        }
        
        // Formata células obrigatórias (Nome e Quantidade) com cor diferente
        if (col <= 1) {
          cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.orange50);
        }
      }
    }
    
    // Adiciona uma linha de instrução
    final instructionCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sampleData.length + 3));
    instructionCell.value = TextCellValue('INSTRUÇÕES:');
    instructionCell.cellStyle = CellStyle(bold: true);
    
    final instruction1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sampleData.length + 4));
    instruction1.value = TextCellValue('• Campos Nome e Quantidade são obrigatórios');
    
    final instruction2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sampleData.length + 5));
    instruction2.value = TextCellValue('• Você pode deletar os dados de exemplo e adicionar seus próprios dados');
    
    final instruction3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sampleData.length + 6));
    instruction3.value = TextCellValue('• Mantenha os cabeçalhos na primeira linha');
    
    final instruction4 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sampleData.length + 7));
    instruction4.value = TextCellValue('• Use ponto (.) como separador decimal para preços');
    
    // Ajusta a largura das colunas
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }
    
    // Gera o arquivo
    final Directory tempDir = Directory.systemTemp;
    const String fileName = 'template_importacao_mercadorias.xlsx';
    final File file = File('${tempDir.path}/$fileName');
    
    final List<int> excelBytes = excel.encode()!;
    await file.writeAsBytes(excelBytes);
    
    AppLogger.info('Template Excel gerado: ${file.path}', 'BulkImportService');
    return file;
  }
}
