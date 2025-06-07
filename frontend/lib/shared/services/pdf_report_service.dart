// lib/services/pdf_report_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../../models/stock_item.dart';
import '../../models/document_model.dart';
import '../../models/store_model.dart';

class PdfReportService {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final NumberFormat _numberFormat = NumberFormat('#,##0.00', 'pt_BR');

  /// Gera relatório de estoque em PDF
  static Future<Uint8List> generateStockReport({
    required List<StockItem> items,
    required Store store,
    String? title,
  }) async {
    final pdf = pw.Document();
    final reportTitle = title ?? 'Relatório de Estoque';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(reportTitle, store),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildStockSummary(items),
          pw.SizedBox(height: 20),
          _buildStockTable(items),
          if (items.isEmpty) _buildEmptyMessage('Nenhum item de estoque encontrado.'),
        ],
      ),
    );

    return pdf.save();
  }

  /// Gera relatório de documentos em PDF
  static Future<Uint8List> generateDocumentReport({
    required List<Document> documents,
    required Store store,
    String? title,
    String? documentType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final reportTitle = title ?? 'Relatório de Documentos';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(reportTitle, store),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildDocumentFilters(documentType, startDate, endDate),
          pw.SizedBox(height: 20),
          _buildDocumentSummary(documents),
          pw.SizedBox(height: 20),
          _buildDocumentTable(documents),
          if (documents.isEmpty) _buildEmptyMessage('Nenhum documento encontrado.'),
        ],
      ),
    );

    return pdf.save();
  }

  /// Gera relatório financeiro em PDF
  static Future<Uint8List> generateFinancialReport({
    required List<Document> documents,
    required Store store,
    required DateTime startDate,
    required DateTime endDate,
    String? title,
  }) async {
    final pdf = pw.Document();
    final reportTitle = title ?? 'Relatório Financeiro';

    // Calcular totais
    final entradas = documents.where((d) => d.type == DocumentType.entrada).toList();
    final saidas = documents.where((d) => d.type == DocumentType.saida).toList();

    final totalEntradas = entradas.fold<double>(0, (sum, doc) => 
        sum + doc.items.fold<double>(0, (itemSum, item) => itemSum + (item.quantity * item.price)));
    final totalSaidas = saidas.fold<double>(0, (sum, doc) => 
        sum + doc.items.fold<double>(0, (itemSum, item) => itemSum + (item.quantity * item.price)));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(reportTitle, store),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildFinancialSummary(totalEntradas, totalSaidas, startDate, endDate),
          pw.SizedBox(height: 20),
          _buildFinancialCharts(entradas, saidas),
          pw.SizedBox(height: 20),
          _buildTopItems(documents),
        ],
      ),
    );

    return pdf.save();
  }

  // Métodos auxiliares para construir os componentes do PDF

  static pw.Widget _buildHeader(String title, Store store) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                store.name,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                _dateTimeFormat.format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(thickness: 2),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 12),
      ),
    );
  }

  static pw.Widget _buildStockSummary(List<StockItem> items) {
    final totalItems = items.length;
    final totalQuantity = items.fold<double>(0, (sum, item) => sum + item.quantity);
    final lowStockItems = items.where((item) => item.quantity < 5).length; // Assumindo 5 como estoque baixo

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total de Itens', totalItems.toString()),
          _buildSummaryItem('Quantidade Total', _numberFormat.format(totalQuantity)),
          _buildSummaryItem('Estoque Baixo', lowStockItems.toString()),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildStockTable(List<StockItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Item', isHeader: true),
            _buildTableCell('Categoria', isHeader: true),
            _buildTableCell('Quantidade', isHeader: true),
            _buildTableCell('Localização', isHeader: true),
          ],
        ),
        // Dados
        ...items.map((item) => pw.TableRow(
          children: [
            _buildTableCell(item.name),
            _buildTableCell(item.properties['category'] ?? 'N/A'),
            _buildTableCell(_numberFormat.format(item.quantity)),
            _buildTableCell(item.properties['location'] ?? 'N/A'),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildDocumentFilters(String? documentType, DateTime? startDate, DateTime? endDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Filtros Aplicados:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          if (documentType != null) pw.Text('Tipo: $documentType'),
          if (startDate != null) pw.Text('Data Inicial: ${_dateFormat.format(startDate)}'),
          if (endDate != null) pw.Text('Data Final: ${_dateFormat.format(endDate)}'),
        ],
      ),
    );
  }

  static pw.Widget _buildDocumentSummary(List<Document> documents) {
    final totalDocs = documents.length;
    final entraDocs = documents.where((d) => d.type == DocumentType.entrada).length;
    final saidaDocs = documents.where((d) => d.type == DocumentType.saida).length;
    final processedDocs = documents.where((d) => d.status == 'PROCESSED').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', totalDocs.toString()),
          _buildSummaryItem('Entradas', entraDocs.toString()),
          _buildSummaryItem('Saídas', saidaDocs.toString()),
          _buildSummaryItem('Processados', processedDocs.toString()),
        ],
      ),
    );
  }

  static pw.Widget _buildDocumentTable(List<Document> documents) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Número', isHeader: true),
            _buildTableCell('Tipo', isHeader: true),
            _buildTableCell('Data', isHeader: true),
            _buildTableCell('Itens', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        // Dados
        ...documents.map((doc) => pw.TableRow(
          children: [
            _buildTableCell(doc.number),
            _buildTableCell(documentTypeToString(doc.type)),
            _buildTableCell(doc.date),
            _buildTableCell(doc.items.length.toString()),
            _buildTableCell(doc.status),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildFinancialSummary(double totalEntradas, double totalSaidas, DateTime startDate, DateTime endDate) {
    final saldo = totalEntradas - totalSaidas;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Período: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildFinancialItem('Total Entradas', totalEntradas, PdfColors.green),
              _buildFinancialItem('Total Saídas', totalSaidas, PdfColors.red),
              _buildFinancialItem('Saldo', saldo, saldo >= 0 ? PdfColors.green : PdfColors.red),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFinancialItem(String label, double value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          _currencyFormat.format(value),
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: color),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildFinancialCharts(List<Document> entradas, List<Document> saidas) {
    // Aqui você pode adicionar gráficos simples usando pw.Chart
    // Por simplicidade, vou apenas mostrar um resumo por tipo
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Análise por Tipo de Documento', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Entradas: ${entradas.length} documentos'),
          pw.Text('Saídas: ${saidas.length} documentos'),
        ],
      ),
    );
  }

  static pw.Widget _buildTopItems(List<Document> documents) {
    // Contar itens mais movimentados
    final itemCounts = <String, int>{};
    for (final doc in documents) {
      for (final item in doc.items) {
        itemCounts[item.name] = (itemCounts[item.name] ?? 0) + 1;
      }
    }

    final sortedItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topItems = sortedItems.take(10).toList();

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Top 10 Itens Mais Movimentados', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ...topItems.map((item) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(item.key),
              pw.Text('${item.value} movimentações'),
            ],
          )),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildEmptyMessage(String message) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(32),
      child: pw.Text(
        message,
        style: const pw.TextStyle(fontSize: 16),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Salva o PDF no dispositivo e retorna o caminho do arquivo
  static Future<String> savePdfToDevice(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, '$fileName.pdf'));
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Compartilha o PDF
  static Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
  }

  /// Visualiza o PDF
  static Future<void> previewPdf(Uint8List pdfBytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: title,
    );
  }
}
