// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/providers/document_provider.dart';
import '/providers/stock_provider.dart';
import '/providers/store_provider.dart';
import '/services/pdf_report_service.dart';
import '/services/simple_report_service.dart';
import '/utils/app_prefs.dart';
import '/utils/error_handler.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedReportType = 'stock_movement';
  String? _selectedCompany;
  String? _selectedBranch;
  String? _selectedWarehouse;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final company = await AppPrefs.getSelectedCompany();
      final branch = await AppPrefs.getSelectedBranch();
      final warehouse = await AppPrefs.getSelectedWarehouse();
      
      if (mounted) {
        setState(() {
          _selectedCompany = company;
          _selectedBranch = branch;
          _selectedWarehouse = warehouse;
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateReport() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      switch (_selectedReportType) {
        case 'stock_movement':
          await _generateStockReportPdf();
          break;
        case 'documents':
          await _generateDocumentReportPdf();
          break;
        case 'inventory':
          await _generateInventoryReportPdf();
          break;
        case 'financial':
          await _generateFinancialReportPdf();
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Relatório gerado com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Erro ao gerar relatório: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // PDF Report Generation Methods (with fallback)
  Future<void> _generateStockReportPdf() async {
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      
      final selectedStore = storeProvider.selectedStore;
      if (selectedStore == null) {
        ErrorHandler.showErrorSnackBar(context, 'Nenhuma loja selecionada');
        return;
      }

      await stockProvider.fetchStockItems();
      final items = stockProvider.items;
      
      if (items.isEmpty) {
        ErrorHandler.showErrorSnackBar(context, 'Nenhum item de estoque encontrado');
        return;
      }

      try {
        final pdfBytes = await PdfReportService.generateStockReport(
          items: items,
          store: selectedStore,
          title: 'Relatório de Estoque - ${selectedStore.name}',
        );

        await PdfReportService.previewPdf(
          pdfBytes, 
          'Relatório de Estoque - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'
        );
      } catch (e) {
        // Fallback to simple text report
        debugPrint('PDF generation failed, using fallback: $e');
        await _generateStockReportFallback();
      }
      
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  Future<void> _generateDocumentReportPdf() async {
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      
      final selectedStore = storeProvider.selectedStore;
      if (selectedStore == null) {
        ErrorHandler.showErrorSnackBar(context, 'Nenhuma loja selecionada');
        return;
      }

      await documentProvider.fetchDocuments();
      
      // Filtrar documentos por período
      final allDocuments = documentProvider.documents;
      final filteredDocuments = allDocuments.where((doc) {
        try {
          final docDate = DateTime.parse(doc.date);
          return docDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                 docDate.isBefore(_endDate.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();

      if (filteredDocuments.isEmpty) {
        ErrorHandler.showErrorSnackBar(context, 'Nenhum documento encontrado no período selecionado');
        return;
      }

      try {
        final pdfBytes = await PdfReportService.generateDocumentReport(
          documents: filteredDocuments,
          store: selectedStore,
          title: 'Relatório de Documentos - ${selectedStore.name}',
          startDate: _startDate,
          endDate: _endDate,
        );

        await PdfReportService.previewPdf(
          pdfBytes, 
          'Relatório de Documentos - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'
        );
      } catch (e) {
        // Fallback to simple text report
        debugPrint('PDF generation failed, using fallback: $e');
        await _generateDocumentReportFallback();
      }
      
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  Future<void> _generateInventoryReportPdf() async {
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      
      final selectedStore = storeProvider.selectedStore;
      if (selectedStore == null) {
        ErrorHandler.showErrorSnackBar(context, 'Nenhuma loja selecionada');
        return;
      }

      await stockProvider.fetchStockItems();
      final items = stockProvider.items;

      try {
        final pdfBytes = await PdfReportService.generateStockReport(
          items: items,
          store: selectedStore,
          title: 'Relatório de Inventário - ${selectedStore.name}',
        );

        await PdfReportService.previewPdf(
          pdfBytes, 
          'Relatório de Inventário - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'
        );
      } catch (e) {
        // Fallback to simple text report
        debugPrint('PDF generation failed, using fallback: $e');
        await _generateStockReportFallback();
      }
      
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  Future<void> _generateFinancialReportPdf() async {
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      
      final selectedStore = storeProvider.selectedStore;
      if (selectedStore == null) {
        ErrorHandler.showErrorSnackBar(context, 'Nenhuma loja selecionada');
        return;
      }

      await documentProvider.fetchDocuments();
      
      // Filtrar documentos por período
      final allDocuments = documentProvider.documents;
      final filteredDocuments = allDocuments.where((doc) {
        try {
          final docDate = DateTime.parse(doc.date);
          return docDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                 docDate.isBefore(_endDate.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();

      try {
        final pdfBytes = await PdfReportService.generateFinancialReport(
          documents: filteredDocuments,
          store: selectedStore,
          startDate: _startDate,
          endDate: _endDate,
          title: 'Relatório Financeiro - ${selectedStore.name}',
        );

        await PdfReportService.previewPdf(
          pdfBytes, 
          'Relatório Financeiro - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'
        );
      } catch (e) {
        // Fallback to simple text report
        debugPrint('PDF generation failed, using fallback: $e');
        await _generateFinancialReportFallback();
      }
      
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: 'Selecionar período',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // Fallback methods using simple report service
  Future<void> _generateStockReportFallback() async {
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      
      final selectedStore = storeProvider.selectedStore;
      if (selectedStore == null) {
        ErrorHandler.showErrorSnackBar(context, 'Nenhuma loja selecionada');
        return;
      }

      await stockProvider.fetchStockItems();
      final items = stockProvider.items;
      
      if (items.isEmpty) {
        ErrorHandler.showErrorSnackBar(context, 'Nenhum item de estoque encontrado');
        return;
      }

      final reportContent = await SimpleReportService.generateStockReport(
        items: items,
        store: selectedStore,
        title: 'Relatório de Estoque - ${selectedStore.name}',
      );

      await SimpleReportService.showReportDialog(
        context,
        reportContent,
        'Relatório de Estoque'
      );
      
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  Future<void> _generateDocumentReportFallback() async {
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      
      final selectedStore = storeProvider.selectedStore;
      if (selectedStore == null) {
        ErrorHandler.showErrorSnackBar(context, 'Nenhuma loja selecionada');
        return;
      }

      await documentProvider.fetchDocuments();
      
      // Filtrar documentos por período
      final allDocuments = documentProvider.documents;
      final filteredDocuments = allDocuments.where((doc) {
        try {
          final docDate = DateTime.parse(doc.date);
          return docDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                 docDate.isBefore(_endDate.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();

      if (filteredDocuments.isEmpty) {
        ErrorHandler.showErrorSnackBar(context, 'Nenhum documento encontrado no período selecionado');
        return;
      }

      final reportContent = await SimpleReportService.generateDocumentReport(
        documents: filteredDocuments,
        store: selectedStore,
        title: 'Relatório de Documentos - ${selectedStore.name}',
        startDate: _startDate,
        endDate: _endDate,
      );

      await SimpleReportService.showReportDialog(
        context,
        reportContent,
        'Relatório de Documentos'
      );
      
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  Future<void> _generateFinancialReportFallback() async {
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      
      final selectedStore = storeProvider.selectedStore;
      if (selectedStore == null) {
        ErrorHandler.showErrorSnackBar(context, 'Nenhuma loja selecionada');
        return;
      }

      await documentProvider.fetchDocuments();
      
      // Filtrar documentos por período
      final allDocuments = documentProvider.documents;
      final filteredDocuments = allDocuments.where((doc) {
        try {
          final docDate = DateTime.parse(doc.date);
          return docDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                 docDate.isBefore(_endDate.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();

      final reportContent = await SimpleReportService.generateFinancialReport(
        documents: filteredDocuments,
        store: selectedStore,
        startDate: _startDate,
        endDate: _endDate,
        title: 'Relatório Financeiro - ${selectedStore.name}',
      );

      await SimpleReportService.showReportDialog(
        context,
        reportContent,
        'Relatório Financeiro'
      );
      
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Report Type Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tipo de Relatório',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedReportType,
                            decoration: const InputDecoration(
                              labelText: 'Selecione o tipo de relatório',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'stock_movement',
                                child: Text('Movimentação de Estoque'),
                              ),
                              DropdownMenuItem(
                                value: 'documents',
                                child: Text('Documentos'),
                              ),
                              DropdownMenuItem(
                                value: 'inventory',
                                child: Text('Inventário'),
                              ),
                              DropdownMenuItem(
                                value: 'financial',
                                child: Text('Relatório Financeiro'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedReportType = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Range Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Período',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              'Período: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Localização',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.business),
                            title: const Text('Empresa'),
                            subtitle: Text(_selectedCompany ?? 'Não selecionada'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.location_city),
                            title: const Text('Filial'),
                            subtitle: Text(_selectedBranch ?? 'Não selecionada'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.warehouse),
                            title: const Text('Armazém'),
                            subtitle: Text(_selectedWarehouse ?? 'Não selecionado'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Generate Report Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateReport,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.file_download),
                    label: Text(_isLoading ? 'Gerando...' : 'Gerar Relatório'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
