// lib/services/simple_report_service.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/models/stock_item.dart';
import '../../core/data/models/document_model.dart';
import '../../core/data/models/store_model.dart';

class SimpleReportService {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final NumberFormat _numberFormat = NumberFormat('#,##0.00', 'pt_BR');

  /// Gera relatório de estoque simples como texto
  static Future<String> generateStockReport({
    required List<StockItem> items,
    required Store store,
    String? title,
  }) async {
    final reportTitle = title ?? 'Relatório de Estoque';
    final buffer = StringBuffer();

    // Header
    buffer.writeln('='.padLeft(60, '='));
    buffer.writeln(reportTitle.toUpperCase().padLeft((60 + reportTitle.length) ~/ 2));
    buffer.writeln('='.padLeft(60, '='));
    buffer.writeln();
    buffer.writeln('Loja: ${store.name}');
    buffer.writeln('Data: ${_dateFormat.format(DateTime.now())}');
    buffer.writeln();

    // Summary
    double totalValue = 0.0;
    int lowStockItems = 0;
    
    for (var item in items) {
      final itemValue = (item.price ?? 0.0) * item.quantity;
      totalValue += itemValue;
      if (item.quantity <= 10) lowStockItems++;
    }

    buffer.writeln('RESUMO:');
    buffer.writeln('-'.padLeft(40, '-'));
    buffer.writeln('Total de itens: ${items.length}');
    buffer.writeln('Valor total do estoque: ${_currencyFormat.format(totalValue)}');
    buffer.writeln('Itens com estoque baixo: $lowStockItems');
    buffer.writeln();

    // Items table
    buffer.writeln('ITENS EM ESTOQUE:');
    buffer.writeln('-'.padLeft(80, '-'));
    buffer.writeln('${_padString('Nome', 25)} ${_padString('Quantidade', 12)} ${_padString('Preço Unit.', 12)} ${_padString('Valor Total', 12)}');
    buffer.writeln('-'.padLeft(80, '-'));

    for (var item in items) {
      final price = item.price ?? 0.0;
      final totalItemValue = price * item.quantity;
      
      buffer.writeln('${_padString(item.name, 25)} ${_padString(item.quantity.toString(), 12)} ${_padString(_currencyFormat.format(price), 12)} ${_padString(_currencyFormat.format(totalItemValue), 12)}');
    }

    buffer.writeln('-'.padLeft(80, '-'));
    
    return buffer.toString();
  }

  /// Gera relatório de documentos simples como texto
  static Future<String> generateDocumentReport({
    required List<DocumentModel> documents,
    required Store store,
    String? title,
    String? documentType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final reportTitle = title ?? 'Relatório de Documentos';
    final buffer = StringBuffer();

    // Header
    buffer.writeln('='.padLeft(60, '='));
    buffer.writeln(reportTitle.toUpperCase().padLeft((60 + reportTitle.length) ~/ 2));
    buffer.writeln('='.padLeft(60, '='));
    buffer.writeln();
    buffer.writeln('Loja: ${store.name}');
    buffer.writeln('Data: ${_dateFormat.format(DateTime.now())}');
    
    if (startDate != null && endDate != null) {
      buffer.writeln('Período: ${_dateFormat.format(startDate)} a ${_dateFormat.format(endDate)}');
    }
    buffer.writeln();

    // Summary by type
    final entradaCount = documents.where((d) => d.type == 'entrada').length;
    final saidaCount = documents.where((d) => d.type == 'saida').length;

    buffer.writeln('RESUMO:');
    buffer.writeln('-'.padLeft(40, '-'));
    buffer.writeln('Total de documentos: ${documents.length}');
    buffer.writeln('Documentos de entrada: $entradaCount');
    buffer.writeln('Documentos de saída: $saidaCount');
    buffer.writeln();

    // Documents table
    buffer.writeln('DOCUMENTOS:');
    buffer.writeln('-'.padLeft(80, '-'));
    buffer.writeln('${_padString('ID', 8)} ${_padString('Tipo', 12)} ${_padString('Data', 12)} ${_padString('Status', 12)}');
    buffer.writeln('-'.padLeft(80, '-'));

    for (var doc in documents) {
      final docDate = DateTime.tryParse(doc.date);
      final formattedDate = docDate != null ? _dateFormat.format(docDate) : doc.date;
      final type = doc.type;
      
      buffer.writeln('${_padString(doc.id?.toString() ?? 'N/A', 8)} ${_padString(type, 12)} ${_padString(formattedDate, 12)} ${_padString('ATIVO', 12)}'); // Default status since status field was removed
    }

    buffer.writeln('-'.padLeft(80, '-'));
    
    return buffer.toString();
  }

  /// Gera relatório financeiro simples como texto
  static Future<String> generateFinancialReport({
    required List<DocumentModel> documents,
    required Store store,
    required DateTime startDate,
    required DateTime endDate,
    String? title,
  }) async {
    final reportTitle = title ?? 'Relatório Financeiro';
    final buffer = StringBuffer();

    // Header
    buffer.writeln('='.padLeft(60, '='));
    buffer.writeln(reportTitle.toUpperCase().padLeft((60 + reportTitle.length) ~/ 2));
    buffer.writeln('='.padLeft(60, '='));
    buffer.writeln();
    buffer.writeln('Loja: ${store.name}');
    buffer.writeln('Data: ${_dateFormat.format(DateTime.now())}');
    buffer.writeln('Período: ${_dateFormat.format(startDate)} a ${_dateFormat.format(endDate)}');
    buffer.writeln();

    // Calculate financial data
    double totalEntradas = 0.0;
    double totalSaidas = 0.0;
    int entradaCount = 0;
    int saidaCount = 0;    for (var doc in documents) {
      // Note: In a real implementation, you'd calculate actual values from document items
      // For now, we'll use a placeholder calculation
      const estimatedValue = 1000.0; // Placeholder
      
      if (doc.type == 'entrada') {
        totalEntradas += estimatedValue;
        entradaCount++;
      } else {
        totalSaidas += estimatedValue;
        saidaCount++;
      }
    }

    final saldo = totalEntradas - totalSaidas;

    buffer.writeln('RESUMO FINANCEIRO:');
    buffer.writeln('-'.padLeft(50, '-'));
    buffer.writeln('${_padString('Total de Entradas:', 25)} ${_currencyFormat.format(totalEntradas)} ($entradaCount documentos)');
    buffer.writeln('${_padString('Total de Saídas:', 25)} ${_currencyFormat.format(totalSaidas)} ($saidaCount documentos)');
    buffer.writeln('-'.padLeft(50, '-'));
    buffer.writeln('${_padString('SALDO:', 25)} ${_currencyFormat.format(saldo)}');
    buffer.writeln();

    // Monthly breakdown
    buffer.writeln('DETALHAMENTO MENSAL:');
    buffer.writeln('-'.padLeft(50, '-'));
    
    final monthlyData = <String, Map<String, dynamic>>{};
    
    for (var doc in documents) {
      final docDate = DateTime.tryParse(doc.date);
      if (docDate != null) {
        final monthKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}';
        
        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {'entradas': 0.0, 'saidas': 0.0, 'count': 0};
        }
        
        monthlyData[monthKey]!['count'] = monthlyData[monthKey]!['count'] + 1;
        
        if (doc.type == 'entrada') {
          monthlyData[monthKey]!['entradas'] = monthlyData[monthKey]!['entradas'] + 1000.0;
        } else {
          monthlyData[monthKey]!['saidas'] = monthlyData[monthKey]!['saidas'] + 1000.0;
        }
      }
    }

    final sortedMonths = monthlyData.keys.toList()..sort();
    
    for (var month in sortedMonths) {
      final data = monthlyData[month]!;
      final monthSaldo = data['entradas'] - data['saidas'];
      
      buffer.writeln('Mês $month:');
      buffer.writeln('  Entradas: ${_currencyFormat.format(data['entradas'])}');
      buffer.writeln('  Saídas: ${_currencyFormat.format(data['saidas'])}');
      buffer.writeln('  Saldo: ${_currencyFormat.format(monthSaldo)}');
      buffer.writeln('  Documentos: ${data['count']}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Mostra o relatório em um diálogo
  static Future<void> showReportDialog(BuildContext context, String reportContent, String title) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Text(
                reportContent,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  /// Helper para formatar strings com padding
  static String _padString(String text, int length) {
    if (text.length >= length) {
      return '${text.substring(0, length - 3)}...';
    }
    return text.padRight(length);
  }
}
