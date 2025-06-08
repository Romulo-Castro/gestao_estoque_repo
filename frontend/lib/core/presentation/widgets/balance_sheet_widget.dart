import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/document_model.dart';
import '../../data/models/balance_sheet_model.dart';
import '../../domain/entities/document_entity.dart';

class BalanceSheetWidget extends StatefulWidget {
  final List<DocumentModel> documents;
  final VoidCallback? onExportBalanceSheet;

  const BalanceSheetWidget({
    super.key,
    required this.documents,
    this.onExportBalanceSheet,
  });

  @override
  State<BalanceSheetWidget> createState() => _BalanceSheetWidgetState();
}

class _BalanceSheetWidgetState extends State<BalanceSheetWidget> {
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
    _calculateBalance();
  }
  void _calculateBalance() {
    final filteredDocuments = widget.documents.where((doc) {
      if (doc.date.isEmpty) return false;
      try {
        final docDate = DateTime.parse(doc.date);
        return _selectedPeriod.contains(docDate);
      } catch (e) {
        return false;
      }
    }).toList();

    _balanceData = BalanceSheetData.fromDocuments(filteredDocuments);
  }

  void _onPeriodChanged(BalanceSheetPeriod? period) {
    if (period != null && period != _selectedPeriod) {
      setState(() {
        _selectedPeriod = period;
      });
      _calculateBalance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPeriodSelector(),
        _buildSummaryCards(),
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
          if (widget.onExportBalanceSheet != null)
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: widget.onExportBalanceSheet,
              tooltip: 'Exportar Balancete',
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Entradas',
                  value: currencyFormat.format(_balanceData.totalInflows),
                  count: '${_balanceData.inflowCount} documentos',
                  color: Colors.green,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Saídas',
                  value: currencyFormat.format(_balanceData.totalOutflows),
                  count: '${_balanceData.outflowCount} documentos',
                  color: Colors.red,
                  icon: Icons.trending_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Saldo Líquido',
            value: currencyFormat.format(_balanceData.netBalance),
            count: _balanceData.netBalance >= 0 ? 'Resultado Positivo' : 'Resultado Negativo',
            color: _balanceData.netBalance >= 0 ? Colors.blue : Colors.orange,
            icon: _balanceData.netBalance >= 0 ? Icons.account_balance : Icons.warning,
            isWide: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String count,
    required Color color,
    required IconData icon,
    bool isWide = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: isWide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isWide ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isWide ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: isWide ? TextAlign.center : TextAlign.start,
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: isWide ? TextAlign.center : TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.blue[700],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue[700],
            tabs: [
              Tab(
                icon: const Icon(Icons.trending_up),
                text: 'Entradas (${_balanceData.inflowCount})',
              ),
              Tab(
                icon: const Icon(Icons.trending_down),
                text: 'Saídas (${_balanceData.outflowCount})',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildItemsList(_balanceData.inflowItems, Colors.green),
                _buildItemsList(_balanceData.outflowItems, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<BalanceSheetItem> items, Color accentColor) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum documento encontrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildBalanceSheetItem(item, accentColor);
      },
    );
  }

  Widget _buildBalanceSheetItem(BalanceSheetItem item, Color accentColor) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentColor.withOpacity(0.1),
          child: Icon(
            _getDocumentIcon(item.type),
            color: accentColor,
            size: 20,
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
              '${dateFormat.format(item.date)} • ${item.itemCount} itens',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Text(
          currencyFormat.format(item.value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: accentColor,
            fontSize: 16,
          ),
        ),
        isThreeLine: true,
      ),
    );
  }  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return Icons.input;
      case DocumentType.saida:
        return Icons.output;
      case DocumentType.unknown:
        return Icons.help_outline;
    }
  }
}
