import 'package:intl/intl.dart';
import '../../models/document_model.dart';
import '../../core/data/models/balance_sheet_model.dart';

enum CSVExportContext {
  allDocuments,
  documentsFiltered,
  balanceSheet,
  stockItems,
  customers,
  suppliers,
}

class CSVExportService {
  static final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _timestampFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  /// Generate CSV content based on context and data
  static String generateCSV({
    required CSVExportContext context,
    required dynamic data,
    String? filterDescription,
  }) {
    switch (context) {
      case CSVExportContext.allDocuments:
        return _generateDocumentsCSV(data as List<Document>, 'Todos os Documentos');
      case CSVExportContext.documentsFiltered:
        return _generateDocumentsCSV(data as List<Document>, filterDescription ?? 'Documentos Filtrados');
      case CSVExportContext.balanceSheet:
        return _generateBalanceSheetCSV(data as BalanceSheetData);
      case CSVExportContext.stockItems:
        return _generateStockItemsCSV(data);
      case CSVExportContext.customers:
        return _generateCustomersCSV(data);
      case CSVExportContext.suppliers:
        return _generateSuppliersCSV(data);
    }
  }

  /// Generate CSV for documents
  static String _generateDocumentsCSV(List<Document> documents, String title) {
    final csvLines = <String>[];
    
    // Header with metadata
    csvLines.add('# $title');
    csvLines.add('# Gerado em: ${_timestampFormat.format(DateTime.now())}');
    csvLines.add('# Total de documentos: ${documents.length}');
    csvLines.add('');
    
    // CSV Headers
    csvLines.add('ID,Número,Tipo,Data,Status,Cliente,Fornecedor,Observações,Total Items,Valor Total');
    
    // Data rows
    for (final doc in documents) {
      final formattedDate = doc.date.isNotEmpty 
          ? _tryFormatDate(doc.date)
          : "Data inválida";
      
      final totalValue = doc.items.fold<double>(0.0, (sum, item) => sum + (item.quantity * item.price));
      
      final row = [
        _escapeCSV(doc.id),
        _escapeCSV(doc.number),
        _escapeCSV(_getDocumentTypeDisplayName(doc.type)),
        _escapeCSV(formattedDate),
        _escapeCSV(doc.status),
        _escapeCSV(doc.customerId ?? ''),
        _escapeCSV(doc.supplierId ?? ''),
        _escapeCSV(doc.notes ?? ''),
        doc.items.length.toString(),
        totalValue.toStringAsFixed(2).replaceAll('.', ','),
      ];
      
      csvLines.add(row.join(','));
    }
    
    // Summary
    csvLines.add('');
    csvLines.add('# Resumo por Tipo:');
    final typeGroups = <DocumentType, int>{};
    for (final doc in documents) {
      typeGroups[doc.type] = (typeGroups[doc.type] ?? 0) + 1;
    }
    
    for (final entry in typeGroups.entries) {
      csvLines.add('# ${_getDocumentTypeDisplayName(entry.key)}: ${entry.value}');
    }
    
    return csvLines.join('\n');
  }

  /// Generate CSV for balance sheet
  static String _generateBalanceSheetCSV(BalanceSheetData balanceData) {
    final csvLines = <String>[];
    
    // Header with metadata
    csvLines.add('# Balancete de Entradas e Saídas');
    csvLines.add('# Gerado em: ${_timestampFormat.format(DateTime.now())}');
    csvLines.add('# Período: ${_dateFormat.format(balanceData.periodStart)} a ${_dateFormat.format(balanceData.periodEnd)}');
    csvLines.add('');
    
    // Summary
    csvLines.add('# RESUMO EXECUTIVO');
    csvLines.add('# Total de Entradas:,${balanceData.totalInflows.toStringAsFixed(2).replaceAll('.', ',')}');
    csvLines.add('# Total de Saídas:,${balanceData.totalOutflows.toStringAsFixed(2).replaceAll('.', ',')}');
    csvLines.add('# Saldo Líquido:,${balanceData.netBalance.toStringAsFixed(2).replaceAll('.', ',')}');
    csvLines.add('# Documentos de Entrada:,${balanceData.inflowCount}');
    csvLines.add('# Documentos de Saída:,${balanceData.outflowCount}');
    csvLines.add('');
    
    // Detailed entries
    csvLines.add('# DETALHAMENTO');
    csvLines.add('Tipo,Doc. ID,Número,Data,Descrição,Valor,Quantidade Items');
    
    // Inflows
    for (final item in balanceData.inflowItems) {
      final row = [
        'ENTRADA',
        _escapeCSV(item.documentId),
        _escapeCSV(item.documentNumber),
        _dateFormat.format(item.date),
        _escapeCSV(item.description),
        item.value.toStringAsFixed(2).replaceAll('.', ','),
        item.itemCount.toString(),
      ];
      csvLines.add(row.join(','));
    }
    
    // Outflows
    for (final item in balanceData.outflowItems) {
      final row = [
        'SAÍDA',
        _escapeCSV(item.documentId),
        _escapeCSV(item.documentNumber),
        _dateFormat.format(item.date),
        _escapeCSV(item.description),
        item.value.toStringAsFixed(2).replaceAll('.', ','),
        item.itemCount.toString(),
      ];
      csvLines.add(row.join(','));
    }
    
    return csvLines.join('\n');
  }

  /// Generate CSV for stock items (placeholder)
  static String _generateStockItemsCSV(dynamic stockItems) {
    final csvLines = <String>[];
    
    csvLines.add('# Relatório de Estoque');
    csvLines.add('# Gerado em: ${_timestampFormat.format(DateTime.now())}');
    csvLines.add('');
    csvLines.add('ID,Nome,Código,Quantidade,Preço Custo,Preço Venda,Unidade,Grupo,Localização');
    
    // This would be implemented when stock items structure is available
    csvLines.add('# Funcionalidade em desenvolvimento');
    
    return csvLines.join('\n');
  }

  /// Generate CSV for customers (placeholder)
  static String _generateCustomersCSV(dynamic customers) {
    final csvLines = <String>[];
    
    csvLines.add('# Relatório de Clientes');
    csvLines.add('# Gerado em: ${_timestampFormat.format(DateTime.now())}');
    csvLines.add('');
    csvLines.add('ID,Nome,Email,Telefone,Endereço,Data Cadastro');
    
    // This would be implemented when customer structure is available
    csvLines.add('# Funcionalidade em desenvolvimento');
    
    return csvLines.join('\n');
  }

  /// Generate CSV for suppliers (placeholder)
  static String _generateSuppliersCSV(dynamic suppliers) {
    final csvLines = <String>[];
    
    csvLines.add('# Relatório de Fornecedores');
    csvLines.add('# Gerado em: ${_timestampFormat.format(DateTime.now())}');
    csvLines.add('');
    csvLines.add('ID,Nome,Email,Telefone,Endereço,Data Cadastro');
    
    // This would be implemented when supplier structure is available
    csvLines.add('# Funcionalidade em desenvolvimento');
    
    return csvLines.join('\n');
  }

  /// Helper method to escape CSV values
  static String _escapeCSV(String value) {
    if (value.isEmpty) return '';
    
    // If the value contains comma, quote, or newline, wrap it in quotes
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      // Escape existing quotes by doubling them
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    
    return value;
  }

  /// Helper method to format dates safely
  static String _tryFormatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return _dateFormat.format(date);
    } catch (e) {
      return dateStr;
    }
  }
  /// Helper method to get document type display name
  static String _getDocumentTypeDisplayName(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return 'Entrada';
      case DocumentType.saida:
        return 'Saída';
      case DocumentType.unknown:
        return 'Desconhecido';
    }
  }

  /// Get contextual filename for export
  static String getContextualFilename(CSVExportContext context, {String? additionalInfo}) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    
    switch (context) {
      case CSVExportContext.allDocuments:
        return 'documentos_todos_$timestamp.csv';
      case CSVExportContext.documentsFiltered:
        final filter = additionalInfo?.replaceAll(' ', '_').toLowerCase() ?? 'filtrados';
        return 'documentos_${filter}_$timestamp.csv';
      case CSVExportContext.balanceSheet:
        return 'balancete_$timestamp.csv';
      case CSVExportContext.stockItems:
        return 'estoque_$timestamp.csv';
      case CSVExportContext.customers:
        return 'clientes_$timestamp.csv';
      case CSVExportContext.suppliers:
        return 'fornecedores_$timestamp.csv';
    }
  }
}
