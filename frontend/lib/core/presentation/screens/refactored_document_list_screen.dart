// frontend/lib/core/presentation/screens/refactored_document_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/document_entity.dart';
import '../../data/models/document_model.dart';
import '../providers/refactored_document_provider.dart';
import '../providers/store_provider.dart';
import '../widgets/app_drawer.dart';
import 'create_document_screen.dart';
import 'document_detail_screen.dart';

class RefactoredDocumentListScreen extends StatefulWidget {
  const RefactoredDocumentListScreen({super.key});

  @override
  State<RefactoredDocumentListScreen> createState() => _RefactoredDocumentListScreenState();
}

class _RefactoredDocumentListScreenState extends State<RefactoredDocumentListScreen>
    with TickerProviderStateMixin {
  
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTypeFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
    );
    
    _fabController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final documentProvider = Provider.of<RefactoredDocumentProvider>(context, listen: false);
    
    if (storeProvider.selectedStoreId != null) {
      documentProvider.setStoreId(storeProvider.selectedStoreId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildFiltersSection(),
          Expanded(child: _buildDocumentsList()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Documentos',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      actions: [
        Consumer<RefactoredDocumentProvider>(
          builder: (context, provider, child) {
            final stats = provider.getDocumentStatistics();
            return IconButton(
              icon: Badge(
                label: Text('${stats['total_documents']}'),
                child: const Icon(Icons.bar_chart),
              ),
              onPressed: () => _showStatisticsDialog(stats),
              tooltip: 'Estatísticas',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _refreshDocuments(),
          tooltip: 'Atualizar',
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar documentos...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filtros avançados',
                ),
              ],
            ),
            if (_hasActiveFilters()) ...[
              const SizedBox(height: 8),
              _buildActiveFiltersChips(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    final chips = <Widget>[];
    
    if (_selectedTypeFilter != null) {
      chips.add(
        Chip(
          label: Text(_selectedTypeFilter == 'entrada' ? 'Entradas' : 'Saídas'),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() => _selectedTypeFilter = null);
            _applyFilters();
          },
        ),
      );
    }
    
    if (_startDateFilter != null || _endDateFilter != null) {
      String dateText = '';
      if (_startDateFilter != null && _endDateFilter != null) {
        dateText = '${_dateFormatter.format(_startDateFilter!)} - ${_dateFormatter.format(_endDateFilter!)}';
      } else if (_startDateFilter != null) {
        dateText = 'A partir de ${_dateFormatter.format(_startDateFilter!)}';
      } else if (_endDateFilter != null) {
        dateText = 'Até ${_dateFormatter.format(_endDateFilter!)}';
      }
      
      chips.add(
        Chip(
          label: Text(dateText),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _startDateFilter = null;
              _endDateFilter = null;
            });
            _applyFilters();
          },
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      children: chips,
    );
  }

  bool _hasActiveFilters() {
    return _selectedTypeFilter != null ||
           _startDateFilter != null ||
           _endDateFilter != null;
  }

  Widget _buildDocumentsList() {
    return Consumer<RefactoredDocumentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando documentos...'),
              ],
            ),
          );
        }

        if (provider.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar documentos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),              Text(
                provider.error ?? 'Erro desconhecido',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshDocuments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        final documents = _getFilteredDocuments(provider.documents);

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _hasActiveFilters() || _searchController.text.isNotEmpty
                      ? 'Nenhum documento encontrado'
                      : 'Nenhum documento criado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _hasActiveFilters() || _searchController.text.isNotEmpty
                      ? 'Tente ajustar os filtros de pesquisa'
                      : 'Crie seu primeiro documento',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                if (!_hasActiveFilters() && _searchController.text.isEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateDocument(),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Documento'),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshDocuments,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return _buildDocumentCard(document);
            },
          ),
        );
      },
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    final isEntrada = document.type.toLowerCase() == 'entrada';
    final color = isEntrada ? Colors.green : Colors.red;
    final icon = isEntrada ? Icons.arrow_downward : Icons.arrow_upward;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _navigateToDocumentDetail(document),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              document.number,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Text(
                                isEntrada ? 'ENTRADA' : 'SAÍDA',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(document.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R\$ ${document.totalValue.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        '${document.items.length} itens',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (document.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  document.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _createAdjustment(document),
                    icon: const Icon(Icons.content_copy, size: 16),
                    label: const Text('Ajuste'),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteDocument(document),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label: const Text('Excluir', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "entrada",
            onPressed: () => _navigateToCreateDocument(DocumentType.entrada),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            child: const Icon(Icons.arrow_downward),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "saida",
            onPressed: () => _navigateToCreateDocument(DocumentType.saida),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            child: const Icon(Icons.arrow_upward),
          ),
        ],
      ),
    );
  }

  // ...existing code for helper methods...

  List<DocumentModel> _getFilteredDocuments(List<DocumentModel> documents) {
    var filtered = documents;

    // Text search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((doc) =>
          doc.number.toLowerCase().contains(query) ||
          doc.description.toLowerCase().contains(query)).toList();
    }

    // Type filter
    if (_selectedTypeFilter != null) {
      filtered = filtered.where((doc) =>
          doc.type.toLowerCase() == _selectedTypeFilter!.toLowerCase()).toList();
    }

    // Date range filter
    if (_startDateFilter != null || _endDateFilter != null) {
      filtered = filtered.where((doc) {
        try {
          final docDate = DateTime.parse(doc.date);
          if (_startDateFilter != null && docDate.isBefore(_startDateFilter!)) {
            return false;
          }
          if (_endDateFilter != null && docDate.isAfter(_endDateFilter!.add(const Duration(days: 1)))) {
            return false;
          }
          return true;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.date);
        final dateB = DateTime.parse(b.date);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    return filtered;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return _dateFormatter.format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _applyFilters() {
    setState(() {}); // Trigger rebuild to apply filters
  }

  Future<void> _refreshDocuments() async {
    final provider = Provider.of<RefactoredDocumentProvider>(context, listen: false);
    await provider.refresh();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtros Avançados'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedTypeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Documento',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'entrada', child: Text('Entradas')),
                    DropdownMenuItem(value: 'saida', child: Text('Saídas')),
                  ],
                  onChanged: (value) => setDialogState(() => _selectedTypeFilter = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Data Inicial',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                          text: _startDateFilter != null
                              ? _dateFormatter.format(_startDateFilter!)
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDateFilter ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setDialogState(() => _startDateFilter = date);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Data Final',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                          text: _endDateFilter != null
                              ? _dateFormatter.format(_endDateFilter!)
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDateFilter ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setDialogState(() => _endDateFilter = date);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedTypeFilter = null;
                  _startDateFilter = null;
                  _endDateFilter = null;
                });
              },
              child: const Text('Limpar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Apply filters
                Navigator.of(context).pop();
                _applyFilters();
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatisticsDialog(Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estatísticas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem('Total de Documentos', '${stats['total_documents']}'),
            _buildStatItem('Entradas', '${stats['total_entradas']}'),
            _buildStatItem('Saídas', '${stats['total_saidas']}'),
            const Divider(),
            _buildStatItem('Valor em Entradas', 'R\$ ${(stats['value_entradas'] as double).toStringAsFixed(2)}'),
            _buildStatItem('Valor em Saídas', 'R\$ ${(stats['value_saidas'] as double).toStringAsFixed(2)}'),
            const Divider(),
            _buildStatItem('Saldo', 'R\$ ${((stats['value_entradas'] as double) - (stats['value_saidas'] as double)).toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateDocument([DocumentType? type]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateDocumentScreen(
          defaultType: type,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _refreshDocuments();
      }
    });
  }

  void _navigateToDocumentDetail(DocumentModel document) {
    Navigator.of(context).push(      MaterialPageRoute(
        builder: (context) => DocumentDetailScreen(documentId: document.id ?? 0),
      ),
    );
  }

  void _createAdjustment(DocumentModel baseDocument) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateDocumentScreen(),
        settings: RouteSettings(
          arguments: {
            'mode': 'adjustment',
            'baseDocument': baseDocument,
          },
        ),
      ),
    ).then((result) {
      if (result == true) {
        _refreshDocuments();
      }
    });
  }

  void _deleteDocument(DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Documento'),
        content: Text('Tem certeza que deseja excluir o documento "${document.number}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final provider = Provider.of<RefactoredDocumentProvider>(context, listen: false);
                await provider.deleteDocument(document.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Documento excluído com sucesso!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir documento: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}