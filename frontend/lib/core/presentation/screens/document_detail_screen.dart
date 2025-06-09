// frontend/lib/screens/document_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/document_model.dart';
import '../providers/document_provider.dart';

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final docProvider = Provider.of<DocumentProvider>(context, listen: false);
        await docProvider.fetchDocumentById(widget.documentId);
        
        if (mounted) {
          if (docProvider.currentDocument == null || docProvider.currentDocument!.id != widget.documentId) {
            if (docProvider.hasError && docProvider.error != null) {
              throw Exception(docProvider.error);
            } else if (docProvider.currentDocument == null && !docProvider.hasError) {
              throw Exception("Documento não encontrado.");
            }
          }
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString().replaceFirst("Exception: ", "");
            _isLoading = false;
          });
        }
      }
    });
  }

  String _getStatusText(String? status) {
    // Since status is removed, always return "Ativo" or remove this method entirely
    return "Ativo";
  }

  Color _getStatusColor(String? status) {
    // Since status is removed, always return active color
    return Colors.green[100]!;
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);
    
    final DocumentModel? documentToDisplay = (docProvider.currentDocument?.id == widget.documentId)
        ? docProvider.currentDocument
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(documentToDisplay != null ? "Documento #${documentToDisplay.id}" : "Detalhe do Documento"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocument,
          ),
          if (documentToDisplay != null) // Removed status check since status field no longer exists
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancelar Documento',
              onPressed: () async {
                final confirmCancel = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Excluir Documento'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tem certeza que deseja excluir permanentemente o documento #${documentToDisplay.id}?'),
                          const SizedBox(height: 12),
                          const Text(
                            'Esta ação irá:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text('• Remover o documento completamente'),
                          const Text('• Reverter os movimentos de estoque'),
                          const Text('• Esta operação NÃO pode ser desfeita'),
                          const SizedBox(height: 12),
                          const Text(
                            'ATENÇÃO: Esta ação é irreversível!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancelar'),
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Sim, Excluir'),
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                        ),
                      ],
                    );
                  },
                );

                if (confirmCancel == true) {
                  if (!mounted) return;
                  setState(() { _isLoading = true; _error = null; });
                  try {
                    await docProvider.cancelDocument(widget.documentId);
                    if (mounted) {
                      // Navigate back to document list since document is deleted
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Documento #${widget.documentId} excluído com sucesso.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _error = "Erro ao excluir documento: ${e.toString().replaceFirst("Exception: ", "")}";
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_error!),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: () {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Erro: $_error", textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDocument,
                    child: const Text("Tentar novamente"),
                  ),
                ],
              ),
            ),
          );
        }
        if (documentToDisplay == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Documento não encontrado ou erro ao carregar.", textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDocument,
                    child: const Text("Tentar Carregar Novamente"),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildDocumentDetails(documentToDisplay);
      }(),
    );
  }

  Widget _buildDocumentDetails(DocumentModel document) {
    final formattedDate = DateFormat("dd/MM/yyyy").format(DateTime.parse(document.date));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Documento #${document.id}",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(_getStatusText(null)), // Pass null since status doesn't exist
                        backgroundColor: _getStatusColor(null),
                        labelStyle: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildInfoRow("Tipo", _getDocumentTypeDisplayName(document.type)),
                  _buildInfoRow("Data", formattedDate),
                  _buildInfoRow("Descrição", document.description.isNotEmpty ? document.description : '-'),
                  _buildInfoRow("Valor Total", "R\$ ${document.totalValue.toStringAsFixed(2)}"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Itens do Documento",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          document.items.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text("Nenhum item encontrado neste documento.")),
                  ),
                )
              : _buildItemsList(document),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildItemsList(DocumentModel document) {
    double documentTotal = document.totalValue;
    
    return Column(
      children: [
        Card(
          elevation: 2,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: document.items.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = document.items[index];
              final lineTotal = item.quantity * item.unitValue;
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  item.stockItemName.isNotEmpty ? item.stockItemName : (item.description.isNotEmpty ? item.description : 'Item ${item.id ?? index + 1}'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Qtd: ${NumberFormat.decimalPattern('pt_BR').format(item.quantity)}"), // Removed unit
                    Text("Preço unit.: R\$ ${item.unitValue.toStringAsFixed(2)}"),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Total Item", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            color: Theme.of(context).primaryColor.withOpacity(0.05),
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
  
  // Helper to get unit abbreviation, assuming item might have a 'unit' field
  // String _getUnitAbbreviation(String? unit) { // Commented out as item.unit is not available
  //   if (unit == null || unit.isEmpty) return '';
  //   // Add more mappings if necessary
  //   if (unit.toLowerCase() == 'kilogram' || unit.toLowerCase() == 'kg') return 'kg';
  //   if (unit.toLowerCase() == 'liter' || unit.toLowerCase() == 'lt') return 'L';
  //   if (unit.toLowerCase() == 'unit' || unit.toLowerCase() == 'un') return 'un';
  //   if (unit.toLowerCase() == 'package' || unit.toLowerCase() == 'pct') return 'pct';
  //   return unit;
  // }

  String _getDocumentTypeDisplayName(String type) {
    if (type.toLowerCase() == 'entrada') return 'Entrada';
    if (type.toLowerCase() == 'saida') return 'Saída';
    if (type.toLowerCase() == 'balanca') return 'Balança';
    return type;
  }
}