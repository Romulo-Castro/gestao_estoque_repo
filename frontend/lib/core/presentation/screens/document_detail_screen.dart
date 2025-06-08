// frontend/lib/screens/document_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/document_model.dart';
import '../providers/document_provider.dart';
import '../providers/store_provider.dart';
import '../../../main.dart'; // Import AppRoutes

class DocumentDetailScreen extends StatefulWidget {
  final int documentId;

  const DocumentDetailScreen({
    required this.documentId,
    super.key,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _isLoading = true;
  DocumentModel? _document;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    // Use addPostFrameCallback to ensure setState is not called during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
        if (storeId == null) {
          throw Exception("Nenhuma loja selecionada");
        }
        final docProvider = Provider.of<DocumentProvider>(context, listen: false);
        final document = await docProvider.fetchDocumentById(widget.documentId);
        
        if (mounted) {
          setState(() {
            _document = document;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    });
  }

  String _getStatusText(String? status) {
    if (status == "CANCELADO") return "Cancelado";
    if (status == "PROCESSADO") return "Processado";
    if (status == "active") return "Ativo";
    return "Rascunho";
  }

  Color _getStatusColor(String? status) {
    if (status == "CANCELADO") return Colors.red[100]!;
    if (status == "PROCESSADO") return Colors.blue[100]!;
    if (status == "active") return Colors.green[100]!;
    return Colors.grey[100]!;
  }

  Future<void> _editDocument() async {
    if (_document == null) return;
    
    // Navigate to edit document screen for creating an adjustment
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.editDocument,
      arguments: {
        'mode': 'adjustment',
        'baseDocument': _document,
      },
    );
    
    // Refresh the document if an adjustment was created
    if (result == true) {
      _loadDocument();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Documento #${widget.documentId}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocument,
          ),
        ],
      ),
      floatingActionButton: _document != null && _document!.status != "CANCELADO"
          ? FloatingActionButton.extended(
              onPressed: _editDocument,
              icon: const Icon(Icons.edit),
              label: const Text("Ajustar"),
              tooltip: "Criar ajuste baseado neste documento",
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Erro: $_error"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDocument,
                        child: const Text("Tentar novamente"),
                      ),
                    ],
                  ),
                )
              : _buildDocumentDetails(),
    );
  }

  Widget _buildDocumentDetails() {
    if (_document == null) {
      return const Center(child: Text("Documento não encontrado"));
    }

    final formattedDate = DateFormat("dd/MM/yyyy").format(DateTime.parse(_document!.date));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Documento #${_document!.id}",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Chip(
                        label: Text(_getStatusText(_document!.status)),
                        backgroundColor: _getStatusColor(_document!.status),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow("Tipo", _getDocumentTypeDisplayName(_document!.type)),
                  _buildInfoRow("Data", formattedDate),
                  _buildInfoRow("Descrição", _document!.description),
                  _buildInfoRow("Valor Total", "R\$ ${_document!.totalValue.toStringAsFixed(2)}"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Itens do Documento",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _document!.items.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Nenhum item encontrado neste documento."),
                  ),
                )
              : _buildItemsList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    double documentTotal = _document!.totalValue;
    
    return Column(
      children: [
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _document!.items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _document!.items[index];
              final lineTotal = item.quantity * item.unitValue;
              
              return ListTile(
                title: Text(
                  item.description.isNotEmpty ? item.description : 'Item ${item.id ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Qtd: ${item.quantity.toStringAsFixed(2)}"),
                    Text("Preço unit.: R\$ ${item.unitValue.toStringAsFixed(2)}"),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Total", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      "R\$ ${lineTotal.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (documentTotal > 0) ...[
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total do Documento",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "R\$ ${documentTotal.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getDocumentTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'entrada':
        return 'Entrada';
      case 'saida':
        return 'Saída';
      default:
        return 'Desconhecido';
    }
  }
}
