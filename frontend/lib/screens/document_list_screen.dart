// frontend/lib/screens/document_list_screen.dart
import "package:flutter/material.dart";
import "package:intl/intl.dart"; // Para formatar data
import "package:provider/provider.dart";
import "/models/document_model.dart";
import "/providers/document_provider.dart";
import "/providers/store_provider.dart";
import "/providers/layout_provider.dart";
import "/screens/edit_document_screen.dart"; // Para criar novo
import "/screens/document_detail_screen.dart"; // Para ver detalhes
import "/widgets/app_drawer.dart";
import "/utils/error_handler.dart";

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  // Filtros
  DocumentType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    // Acessar o provider após o build inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
      if (storeId != null) {
        Provider.of<DocumentProvider>(context, listen: false).setStoreId(storeId);
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  // Helper para obter ícone baseado no tipo
  IconData _getDocIcon(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return Icons.input;
      case DocumentType.saida:
        return Icons.output;
      case DocumentType.ajusteEntrada:
        return Icons.add_circle_outline;
      case DocumentType.ajusteSaida:
        return Icons.remove_circle_outline;
      case DocumentType.transferencia:
        return Icons.swap_horiz;
      case DocumentType.ajuste:
        return Icons.tune;
      case DocumentType.unknown:
        return Icons.help_outline;
    }
  }

  // Helper para obter cor baseado no tipo/status
  Color _getDocColor(DocumentType type, String? status) {
    if (status == "CANCELADO") return Colors.grey;
    switch (type) {
      case DocumentType.entrada:
      case DocumentType.ajusteEntrada:
        return Colors.green;
      case DocumentType.saida:
      case DocumentType.ajusteSaida:
        return Colors.red;
      case DocumentType.transferencia:
        return Colors.blue;
      case DocumentType.ajuste:
        return Colors.orange;
      case DocumentType.unknown:
        return Colors.grey;
    }
  }

  // Helper para converter DocumentType para String
  String documentTypeToString(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return 'Entrada';
      case DocumentType.saida:
        return 'Saída';
      case DocumentType.transferencia:
        return 'Transferência';
      case DocumentType.ajuste:
        return 'Ajuste';
      case DocumentType.ajusteEntrada:
        return 'Ajuste Entrada';
      case DocumentType.ajusteSaida:
        return 'Ajuste Saída';
      case DocumentType.unknown:
        return 'Desconhecido';
    }
  }

  // Método para mostrar o diálogo de filtros
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Filtrar Documentos"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtro por tipo
                  const Text("Tipo de Documento:"),
                  DropdownButton<DocumentType?>(
                    isExpanded: true,
                    value: _selectedType,
                    items: [
                      const DropdownMenuItem<DocumentType?>(
                        value: null,
                        child: Text("Todos"),
                      ),
                      ...DocumentType.values.map((type) {
                        return DropdownMenuItem<DocumentType?>(
                          value: type,
                          child: Text(documentTypeToString(type)),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtro por data inicial
                  const Text("Data Inicial:"),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_startDate == null 
                          ? "Não definida" 
                          : DateFormat("dd/MM/yyyy").format(_startDate!)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                            });
                          }
                        },
                      ),
                      if (_startDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtro por data final
                  const Text("Data Final:"),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_endDate == null 
                          ? "Não definida" 
                          : DateFormat("dd/MM/yyyy").format(_endDate!)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                            });
                          }
                        },
                      ),
                      if (_endDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _endDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _applyFilters();
                },
                child: const Text("Aplicar"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedType = null;
                    _startDate = null;
                    _endDate = null;
                  });
                  Navigator.of(context).pop();
                  _applyFilters();
                },
                child: const Text("Limpar Filtros"),
              ),
            ],
          );
        },
      ),
    );
  }

  // Método para aplicar os filtros
  void _applyFilters() {
    final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
    if (storeId == null) return;

    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    
    // Se não houver filtros, buscar todos os documentos
    if (_selectedType == null && _startDate == null && _endDate == null) {
      docProvider.fetchDocuments();
      return;
    }

    // Converter datas para string no formato esperado pela API
    String? startDateStr;
    String? endDateStr;
    if (_startDate != null) {
      startDateStr = DateFormat("yyyy-MM-dd").format(_startDate!);
    }
    if (_endDate != null) {
      endDateStr = DateFormat("yyyy-MM-dd").format(_endDate!);
    }
    
    // Montar mapa de filtros e chamar o provedor
    final filters = <String, dynamic>{};
    if (_selectedType != null) filters['type'] = _selectedType!.toJson();
    if (startDateStr != null) filters['startDate'] = startDateStr;
    if (endDateStr != null) filters['endDate'] = endDateStr;
    docProvider.fetchDocumentsWithFilters(filters);
  }

  @override
  Widget build(BuildContext context) {
    // Observar o ID da loja selecionada
    final storeId = context.watch<StoreProvider>().selectedStoreId;
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);

    // Se a loja mudar, atualizar o provider
    if (storeId != null) {
      docProvider.setStoreId(storeId);
    }

    // Se não houver loja selecionada, mostra uma mensagem
    if (storeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Documentos")),
        drawer: const AppDrawer(),
        body: const Center(
          child: Text("Por favor, selecione uma loja primeiro."),
        ),
      );
    }

    return Scaffold(      appBar: AppBar(
        title: const Text("Documentos"),
        actions: [
          // Layout toggle button
          Consumer<LayoutProvider>(
            builder: (ctx, layoutProvider, _) => IconButton(
              icon: Icon(layoutProvider.documentLayoutType.icon),
              tooltip: "Alterar layout: ${layoutProvider.documentLayoutType.displayName}",
              onPressed: () => layoutProvider.toggleDocumentLayout(),
            ),
          ),
          // Botão de filtro implementado
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: "Filtrar Documentos",
            onPressed: _showFilterDialog,
          ),
          Consumer<DocumentProvider>(
            builder: (ctx, provider, _) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : () => provider.fetchDocuments(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<DocumentProvider>(
        builder: (ctx, docProvider, child) {
          if (docProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (docProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Erro: ${docProvider.error}"),
                  ElevatedButton(
                    onPressed: () => docProvider.fetchDocuments(),
                    child: const Text("Tentar Novamente"),
                  ),
                ],
              ),
            );
          }

          if (docProvider.documents.isEmpty) {
            return const Center(
              child: Text("Nenhum documento encontrado."),
            );
          }          // Layout-based document display
          return Consumer<LayoutProvider>(
            builder: (context, layoutProvider, child) {
              return _buildLayoutBasedView(docProvider, layoutProvider.documentLayoutType);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const EditDocumentScreen(), // Tela para criar novo
            ),
          );
        },
      ),
    );
  }

  // Layout-based view methods
  Widget _buildLayoutBasedView(DocumentProvider docProvider, LayoutType layoutType) {
    switch (layoutType) {
      case LayoutType.list:
        return _buildListView(docProvider);
      case LayoutType.grid:
        return _buildGridView(docProvider);
      case LayoutType.card:
        return _buildCardView(docProvider);
    }
  }

  Widget _buildListView(DocumentProvider docProvider) {
    return ListView.builder(
      itemCount: docProvider.documents.length,
      itemBuilder: (ctx, index) {
        final doc = docProvider.documents[index];
        return _buildDocumentListTile(doc);
      },
    );
  }

  Widget _buildGridView(DocumentProvider docProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: docProvider.documents.length,
      itemBuilder: (ctx, index) {
        final doc = docProvider.documents[index];
        return _buildDocumentGridCard(doc);
      },
    );
  }

  Widget _buildCardView(DocumentProvider docProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: docProvider.documents.length,
      itemBuilder: (ctx, index) {
        final doc = docProvider.documents[index];
        return _buildDocumentCard(doc);
      },
    );
  }
  Widget _buildDocumentListTile(Document doc) {
    final formattedDate = doc.date.isNotEmpty 
        ? DateFormat("dd/MM/yyyy").format(DateTime.parse(doc.date))
        : "Data inválida";
    final color = _getDocColor(doc.type, doc.status);

    return ListTile(
      leading: Icon(_getDocIcon(doc.type), color: color),
      title: Text("#${doc.id} - ${documentTypeToString(doc.type)}"),
      subtitle: Text("Data: $formattedDate - ${doc.status}"),
      trailing: _buildDocumentTrailingAction(doc),
      onTap: () => _navigateToDocumentDetail(doc),
    );
  }
  Widget _buildDocumentGridCard(Document doc) {
    final formattedDate = doc.date.isNotEmpty 
        ? DateFormat("dd/MM/yyyy").format(DateTime.parse(doc.date))
        : "Data inválida";
    final color = _getDocColor(doc.type, doc.status);

    return Card(
      child: InkWell(
        onTap: () => _navigateToDocumentDetail(doc),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getDocIcon(doc.type), color: color, size: 40),
              const SizedBox(height: 8),
              Text(
                "#${doc.id}",
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                documentTypeToString(doc.type),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              Text(
                doc.status,
                style: TextStyle(fontSize: 10, color: color),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _buildDocumentTrailingAction(doc),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDocumentCard(Document doc) {
    final formattedDate = doc.date.isNotEmpty 
        ? DateFormat("dd/MM/yyyy").format(DateTime.parse(doc.date))
        : "Data inválida";
    final color = _getDocColor(doc.type, doc.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      child: InkWell(
        onTap: () => _navigateToDocumentDetail(doc),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(_getDocIcon(doc.type), color: color, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "#${doc.id} - ${documentTypeToString(doc.type)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("Data: $formattedDate"),
                    Text(
                      "Status: ${doc.status}",
                      style: TextStyle(color: color),
                    ),
                  ],
                ),
              ),
              _buildDocumentTrailingAction(doc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTrailingAction(Document doc) {
    return doc.status == "CANCELADO"
        ? const Icon(Icons.cancel, color: Colors.grey)
        : IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: "Cancelar Documento",
            onPressed: () => _confirmCancelDocument(doc),
          );
  }

  void _navigateToDocumentDetail(Document doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DocumentDetailScreen(documentId: int.parse(doc.id)),
      ),
    );
  }

  Future<void> _confirmCancelDocument(Document doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Cancelamento"),
        content: Text("Tem certeza que deseja cancelar o documento #${doc.id}? Isso reverterá os movimentos de estoque associados."),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Não")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Sim, Cancelar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        final docProvider = Provider.of<DocumentProvider>(context, listen: false);
        await docProvider.cancelDocument(int.parse(doc.id));
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(context, "Documento cancelado!");
        }
      } catch (e) {      if (mounted) {
          ErrorHandler.showErrorSnackBar(context, "Erro ao cancelar: $e");
        }
      }
    }
  }
}
