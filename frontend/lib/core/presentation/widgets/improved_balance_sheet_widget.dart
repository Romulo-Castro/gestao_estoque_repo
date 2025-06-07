// Improved Balance Sheet Widget with Clean Architecture support
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/balance_sheet_model.dart';
import '../../data/models/document_model.dart';

class ImprovedBalanceSheetWidget extends StatefulWidget {
  final List<DocumentModel> documents;
  final VoidCallback? onExportBalanceSheet;

  const ImprovedBalanceSheetWidget({
    super.key,
    required this.documents,
    this.onExportBalanceSheet,
  });

  @override
  State<ImprovedBalanceSheetWidget> createState() => _ImprovedBalanceSheetWidgetState();
}

class _ImprovedBalanceSheetWidgetState extends State<ImprovedBalanceSheetWidget> {
  BalanceSheetPeriod _selectedPeriod = BalanceSheetPeriod.thisMonth();
  late BalanceSheetData _balanceData;

  final List<BalanceSheetPeriod> _availablePeriods = [
    BalanceSheetPeriod.today(),
    BalanceSheetPeriod.thisWeek(),
    BalanceSheetPeriod.thisMonth(),
    BalanceSheetPeriod.all(),
  ];

  @override
  void initState() {
    super.initState();
    _updateBalanceData();
  }

  @override
  void didUpdateWidget(ImprovedBalanceSheetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documents != widget.documents) {
      _updateBalanceData();
    }
  }

  void _updateBalanceData() {
    print('[ImprovedBalanceSheetWidget] Starting balance calculation');
    print('[ImprovedBalanceSheetWidget] Total documents received: ${widget.documents.length}');
    
    if (widget.documents.isEmpty) {
      print('[ImprovedBalanceSheetWidget] No documents available');
      setState(() {
        _balanceData = BalanceSheetData.empty();
      });
      return;
    }    // Filter and validate documents
    final validDocuments = <models.Document>[];
    for (final doc in widget.documents) {
      if (doc.status == 'CANCELADO') {
        print('[ImprovedBalanceSheetWidget] Skipping cancelled document: ${doc.number}');
        continue;
      }

      if (doc.date.isEmpty) {
        print('[ImprovedBalanceSheetWidget] Document ${doc.number} has empty date - skipping');
        continue;
      }

      try {
        final docDate = DateTime.parse(doc.date);
        final isInPeriod = _selectedPeriod.contains(docDate);
        print('[ImprovedBalanceSheetWidget] Document ${doc.number}: '
              'type=${doc.type}, date=${doc.date}, value=${doc.totalAmount}, '
              'status=${doc.status}, inPeriod=$isInPeriod');
        
        if (isInPeriod) {
          validDocuments.add(doc);
        }
      } catch (e) {
        print('[ImprovedBalanceSheetWidget] Failed to parse date for document ${doc.number}: '
              '${doc.date}, error: $e');
      }
    }

    print('[ImprovedBalanceSheetWidget] Valid documents for calculation: ${validDocuments.length}');

    // Calculate balance using both current and improved logic
    setState(() {
      _balanceData = BalanceSheetData.fromDocuments(validDocuments);
      
      // Enhanced calculation validation
      double totalInflows = 0.0;
      double totalOutflows = 0.0;
      int inflowCount = 0;
      int outflowCount = 0;      for (final doc in validDocuments) {
        if (doc.type == models.DocumentType.entrada) {
          totalInflows += doc.totalAmount;
          inflowCount++;
          print('[ImprovedBalanceSheetWidget] Adding inflow: ${doc.number} = ${doc.totalAmount}');
        } else if (doc.type == models.DocumentType.saida) {
          totalOutflows += doc.totalAmount;
          outflowCount++;
          print('[ImprovedBalanceSheetWidget] Adding outflow: ${doc.number} = ${doc.totalAmount}');
        }
      }

      final netBalance = totalInflows - totalOutflows;
      
      print('[ImprovedBalanceSheetWidget] Manual calculation:');
      print('  - Total Inflows: $totalInflows (count: $inflowCount)');
      print('  - Total Outflows: $totalOutflows (count: $outflowCount)');
      print('  - Net Balance: $netBalance');
      
      print('[ImprovedBalanceSheetWidget] BalanceSheetData calculation:');
      print('  - Total Inflows: ${_balanceData.totalInflows}');
      print('  - Total Outflows: ${_balanceData.totalOutflows}');
      print('  - Net Balance: ${_balanceData.netBalance}');
      
      // Verify calculations match
      if ((totalInflows - _balanceData.totalInflows).abs() > 0.01 ||
          (totalOutflows - _balanceData.totalOutflows).abs() > 0.01) {
        print('[ImprovedBalanceSheetWidget] WARNING: Calculation mismatch detected!');
      } else {
        print('[ImprovedBalanceSheetWidget] Calculations verified - all correct');
      }
    });
  }

  void _onPeriodChanged(BalanceSheetPeriod? period) {
    if (period != null && period != _selectedPeriod) {
      print('[ImprovedBalanceSheetWidget] Period changed to: ${period.displayName}');
      setState(() {
        _selectedPeriod = period;
      });
      _updateBalanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPeriodSelector(),
        _buildEnhancedSummaryCards(),
        const SizedBox(height: 16),
        Expanded(child: _buildDetailedView()),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Colors.blue),
          const SizedBox(width: 8),
          const Text(
            'Período:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<BalanceSheetPeriod>(
              value: _selectedPeriod,
              onChanged: _onPeriodChanged,
              isExpanded: true,
              underline: Container(),
              items: _availablePeriods.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period.displayName),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryCards() {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Debug info card
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações de Debug',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Documentos totais: ${widget.documents.length}'),
                  Text('Período: ${_selectedPeriod.displayName}'),
                  Text('Entradas: ${_balanceData.inflowCount}'),
                  Text('Saídas: ${_balanceData.outflowCount}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Financial summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Entradas',
                  formatter.format(_balanceData.totalInflows),
                  Colors.green,
                  Icons.trending_up,
                  '${_balanceData.inflowCount} documento(s)',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Saídas',
                  formatter.format(_balanceData.totalOutflows),
                  Colors.red,
                  Icons.trending_down,
                  '${_balanceData.outflowCount} documento(s)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Saldo Líquido',
            formatter.format(_balanceData.netBalance),
            _balanceData.netBalance >= 0 ? Colors.green : Colors.red,
            _balanceData.netBalance >= 0 ? Icons.account_balance : Icons.warning,
            _balanceData.netBalance >= 0 ? 'Positivo' : 'Negativo',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon, String subtitle) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedView() {
    if (_balanceData.inflowItems.isEmpty && _balanceData.outflowItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum documento encontrado para o período selecionado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                text: 'Entradas (${_balanceData.inflowCount})',
                icon: const Icon(Icons.trending_up),
              ),
              Tab(
                text: 'Saídas (${_balanceData.outflowCount})',
                icon: const Icon(Icons.trending_down),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildDocumentList(_balanceData.inflowItems, Colors.green),
                _buildDocumentList(_balanceData.outflowItems, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList(List<BalanceSheetItem> items, Color color) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Nenhum documento encontrado',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),              child: Icon(
                item.type == models.DocumentType.entrada 
                    ? Icons.trending_up 
                    : Icons.trending_down,
                color: color,
              ),
            ),
            title: Text(
              'Doc. ${item.documentNumber}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description),
                Text(
                  DateFormat('dd/MM/yyyy').format(item.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Text(
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                  .format(item.value),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
