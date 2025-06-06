// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/document_provider.dart';
import '/providers/stock_provider.dart';
import '/providers/store_provider.dart';
import '/utils/app_prefs.dart';

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

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final documentProvider = context.read<DocumentProvider>();
      final stockProvider = context.read<StockProvider>();

      switch (_selectedReportType) {
        case 'stock_movement':
          await _generateStockMovementReport(stockProvider);
          break;
        case 'documents':
          await _generateDocumentReport(documentProvider);
          break;
        case 'inventory':
          await _generateInventoryReport(stockProvider);
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

  Future<void> _generateStockMovementReport(StockProvider provider) async {
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final currentStore = storeProvider.selectedStore;
      
      if (currentStore == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Selecione uma loja primeiro"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await provider.fetchStockItems();
      final items = provider.items;
      
      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Nenhum item em estoque encontrado"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Generate a simple stock movement report
      String reportContent = "RELATÓRIO DE MOVIMENTAÇÃO DE ESTOQUE\n";
      reportContent += "Loja: ${currentStore.name}\n";
      reportContent += "Data: ${DateTime.now().toString().split(' ')[0]}\n\n";
      reportContent += "ITENS EM ESTOQUE:\n";
      
      for (var item in items) {
        reportContent += "${item.name} - Qtd: ${item.quantity} - Preço: R\$ ${item.price?.toStringAsFixed(2) ?? 'N/A'}\n";
      }

      // Here you would typically save or share the report
      debugPrint(reportContent);
      
    } catch (e) {
      debugPrint("Erro ao gerar relatório: $e");
      rethrow;
    }
  }

  Future<void> _generateDocumentReport(DocumentProvider provider) async {
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final currentStore = storeProvider.selectedStore;
      
      if (currentStore == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Selecione uma loja primeiro"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await provider.fetchDocuments();
      final documents = provider.documents;
      
      if (documents.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Nenhum documento encontrado"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Generate document report
      String reportContent = "RELATÓRIO DE DOCUMENTOS\n";
      reportContent += "Loja: ${currentStore.name}\n";
      reportContent += "Data: ${DateTime.now().toString().split(' ')[0]}\n\n";
      reportContent += "DOCUMENTOS:\n";
      
      for (var doc in documents) {
        reportContent += "${doc.type.toString().split('.').last} - ${doc.number} - ${doc.date.toString().split(' ')[0]}\n";
      }

      debugPrint(reportContent);
      
    } catch (e) {
      debugPrint("Erro ao gerar relatório de documentos: $e");
      rethrow;
    }
  }

  Future<void> _generateInventoryReport(StockProvider provider) async {
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final currentStore = storeProvider.selectedStore;
      
      if (currentStore == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Selecione uma loja primeiro"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await provider.fetchStockItems();
      final items = provider.items;
      
      // Generate inventory report with totals
      String reportContent = "RELATÓRIO DE INVENTÁRIO\n";
      reportContent += "Loja: ${currentStore.name}\n";
      reportContent += "Data: ${DateTime.now().toString().split(' ')[0]}\n\n";
      
      double totalValue = 0.0;
      int totalItems = 0;
      
      reportContent += "INVENTÁRIO COMPLETO:\n";
      for (var item in items) {
        final itemValue = (item.price ?? 0.0) * item.quantity;
        totalValue += itemValue;
        totalItems++;
        reportContent += "${item.name} - Qtd: ${item.quantity} - Valor Total: R\$ ${itemValue.toStringAsFixed(2)}\n";
      }
      
      reportContent += "\nRESUMO:\n";
      reportContent += "Total de itens: $totalItems\n";
      reportContent += "Valor total do inventário: R\$ ${totalValue.toStringAsFixed(2)}\n";

      debugPrint(reportContent);
      
    } catch (e) {
      debugPrint("Erro ao gerar relatório de inventário: $e");
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
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectDate(context, true),
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(
                                    'De: ${_startDate.toString().split(' ')[0]}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectDate(context, false),
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(
                                    'Até: ${_endDate.toString().split(' ')[0]}',
                                  ),
                                ),
                              ),
                            ],
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
