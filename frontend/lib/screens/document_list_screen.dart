import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/document_model.dart';
import '../models/balance_sheet_model.dart';
import '../providers/document_provider.dart';
import '../providers/store_provider.dart';
import '../screens/edit_document_screen.dart';
import '../screens/document_detail_screen.dart';
import '../widgets/app_drawer.dart';
import '../core/presentation/widgets/improved_balance_sheet_widget.dart';
import '../services/csv_export_service.dart';
import '../utils/error_handler.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen>
    with SingleTickerProviderStateMixin {  late TabController _tabController;
  bool _mounted = true;
  final Set<String> _selectedDocuments = {};
  bool _isSelectionMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  // Tab filters
  final List<String> _tabFilters = ['TODOS', 'ENTRADA', 'SAÍDA', 'BALANÇA'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabFilters.length, vsync: this);
    
    // Initialize document provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
      if (storeId != null) {
        Provider.of<DocumentProvider>(context, listen: false).setStoreId(storeId);
      }
    });
  }
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _mounted = false;
    super.dispose();
  }
  // Helper methods for document type conversion
  IconData _getDocIcon(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return Icons.input;
      case DocumentType.saida:
        return Icons.output;
      case DocumentType.unknown:
        return Icons.help_outline;
    }
  }
  Color _getDocColor(DocumentType type, String? status) {
    if (status == "CANCELADO") return Colors.grey;
    switch (type) {
      case DocumentType.entrada:
        return Colors.green;
      case DocumentType.saida:
        return Colors.red;
      case DocumentType.unknown:
        return Colors.grey;
    }
  }
  String documentTypeToString(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return 'Entrada';
      case DocumentType.saida:
        return 'Saída';
      case DocumentType.unknown:
        return 'Desconhecido';
    }
  }  // Filter documents based on selected tab and search query
  List<Document> _getFilteredDocuments(List<Document> documents, String filter) {
    List<Document> filteredByTab;
    
    if (filter == 'TODOS') {
      filteredByTab = documents;
    } else {
      filteredByTab = documents.where((doc) {
        switch (filter) {
          case 'ENTRADA':
            return doc.type == DocumentType.entrada;
          case 'SAÍDA':
            return doc.type == DocumentType.saida;
          case 'BALANÇA':
            // For balance sheet, include all documents that affect financial flow
            return doc.type == DocumentType.entrada || 
                   doc.type == DocumentType.saida;
          default:
            return true;
        }
      }).toList();
    }
    
    // Apply search filter if search query exists
    if (_searchQuery.isNotEmpty) {
      filteredByTab = filteredByTab.where((doc) {
        final searchLower = _searchQuery.toLowerCase();
        return doc.id.toLowerCase().contains(searchLower) ||
               documentTypeToString(doc.type).toLowerCase().contains(searchLower) ||
               doc.status.toLowerCase().contains(searchLower) ||
               doc.date.toLowerCase().contains(searchLower);
      }).toList();
    }
    
    return filteredByTab;
  }
  void _toggleSelection(String docId) {
    setState(() {
      if (_selectedDocuments.contains(docId)) {
        _selectedDocuments.remove(docId);
        if (_selectedDocuments.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedDocuments.add(docId);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedDocuments.clear();
      _isSelectionMode = false;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }
  Future<void> _exportDocuments() async {
    try {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final currentTab = _tabFilters[_tabController.index];
      final filteredDocs = _getFilteredDocuments(docProvider.documents, currentTab);
      
      if (filteredDocs.isEmpty) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, "Nenhum documento para exportar.");
        }
        return;
      }

      String csvContent;
      String contextDescription;

      // Generate contextual CSV based on current tab
      switch (currentTab) {
        case 'BALANÇA':
          final balanceData = BalanceSheetData.fromDocuments(filteredDocs);
          csvContent = CSVExportService.generateCSV(
            context: CSVExportContext.balanceSheet,
            data: balanceData,
          );
          contextDescription = 'Balancete';
          break;
        
        case 'TODOS':
          csvContent = CSVExportService.generateCSV(
            context: CSVExportContext.allDocuments,
            data: filteredDocs,
          );
          contextDescription = 'Todos os Documentos';
          break;
        
        default:
          csvContent = CSVExportService.generateCSV(
            context: CSVExportContext.documentsFiltered,
            data: filteredDocs,
            filterDescription: currentTab,
          );
          contextDescription = 'Documentos - $currentTab';
          break;
      }
      
      // For web - create download link (simplified approach)
      // In a real implementation, you would use 'dart:html' for web downloads
      // For now, we'll show the content length as confirmation
      final contentLength = csvContent.length;
      final filename = CSVExportService.getContextualFilename(
        currentTab == 'BALANÇA' ? CSVExportContext.balanceSheet : 
        currentTab == 'TODOS' ? CSVExportContext.allDocuments : CSVExportContext.documentsFiltered,
        additionalInfo: currentTab,
      );
      
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context, 
          "Exportação de $contextDescription concluída!\n${filteredDocs.length} registros • $filename ($contentLength caracteres)."
        );
      }
      
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, "Erro ao exportar: $e");
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Configurações"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.view_list),
              title: const Text("Visualização"),
              subtitle: const Text("Configurar modo de exibição"),
              onTap: () {
                Navigator.of(ctx).pop();
                // Future: Implement view settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text("Filtros"),
              subtitle: const Text("Configurar filtros padrão"),
              onTap: () {
                Navigator.of(ctx).pop();
                // Future: Implement filter settings
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  Future<void> _processSelectedDocuments() async {
    try {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      int processedCount = 0;
      
      for (final docId in _selectedDocuments) {
        await docProvider.updateDocumentStatus(int.parse(docId), 'PROCESSADO');
        processedCount++;
      }
      
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          "$processedCount documento(s) processado(s)!",
        );
      }
      _clearSelection();
      
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, "Erro ao processar: $e");
      }
    }
  }

  Future<void> _generateReceiptForSelected() async {
    try {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final selectedDocs = docProvider.documents
          .where((doc) => _selectedDocuments.contains(doc.id))
          .toList();
      
      if (selectedDocs.isEmpty) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, "Nenhum documento selecionado.");
        }
        return;
      }

      // Generate receipt content
      final receiptLines = <String>[];
      receiptLines.add('RECIBO DE DOCUMENTOS');
      receiptLines.add('Data: ${DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now())}');
      receiptLines.add('');
      
      for (final doc in selectedDocs) {
        final formattedDate = doc.date.isNotEmpty 
            ? DateFormat("dd/MM/yyyy").format(DateTime.parse(doc.date))
            : "Data inválida";
        receiptLines.add('Doc #${doc.id} - ${documentTypeToString(doc.type)} - $formattedDate');
      }
      
      receiptLines.add('');
      receiptLines.add('Total de documentos: ${selectedDocs.length}');
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Recibo Gerado"),
            content: SingleChildScrollView(
              child: Text(receiptLines.join('\n')),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Fechar"),
              ),
            ],
          ),
        );
      }
      
      _clearSelection();
      
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, "Erro ao gerar recibo: $e");
      }
    }
  }

  Future<void> _printSelectedDocuments() async {
    try {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final selectedDocs = docProvider.documents
          .where((doc) => _selectedDocuments.contains(doc.id))
          .toList();
      
      if (selectedDocs.isEmpty) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, "Nenhum documento selecionado.");
        }
        return;
      }

      // For web, show print dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Imprimir Documentos"),
            content: Text("Preparando impressão de ${selectedDocs.length} documento(s)..."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (mounted) {
                    ErrorHandler.showSuccessSnackBar(
                      context,
                      "${selectedDocs.length} documento(s) enviado(s) para impressão!",
                    );
                  }
                },
                child: const Text("Imprimir"),
              ),
            ],
          ),
        );
      }
      
      _clearSelection();
      
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, "Erro ao imprimir: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    
    if (storeProvider.selectedStoreId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Docu...")),
        drawer: const AppDrawer(),
        body: const Center(
          child: Text("Por favor, selecione uma loja primeiro."),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildStoreBar(),
          _buildTabBar(),
          Expanded(child: _buildDocumentList()),
          if (_isSelectionMode) _buildQuickActionBar(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _isSearching 
          ? TextField(
              controller: _searchController,
              onChanged: _updateSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Pesquisar documentos...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            )
          : const Text("Docu..."),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: _toggleSearch,
        ),
        IconButton(
          icon: const Icon(Icons.file_download),
          onPressed: _exportDocuments,
        ),
        IconButton(
          icon: const Icon(Icons.add_box),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => const EditDocumentScreen(),
              ),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                Provider.of<DocumentProvider>(context, listen: false).fetchDocuments();
                break;
              case 'settings':
                _showSettingsDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Atualizar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Configurações'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoreBar() {
    return Consumer<StoreProvider>(
      builder: (context, storeProvider, child) {
        final storeName = storeProvider.selectedStore?.name ?? 'Main Store';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Text(
            storeName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        tabs: _tabFilters.map((filter) => Tab(text: filter)).toList(),
        labelColor: Colors.blue[700],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue[700],
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }
  Widget _buildDocumentList() {
    return Consumer<DocumentProvider>(
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
        }

        return TabBarView(
          controller: _tabController,
          children: _tabFilters.map((filter) {
            final filteredDocs = _getFilteredDocuments(docProvider.documents, filter);
              // Special handling for Balance Sheet tab
            if (filter == 'BALANÇA') {
              print('[DocumentListScreen] BALANÇA tab - Total documents: ${docProvider.documents.length}');
              print('[DocumentListScreen] BALANÇA tab - Filtered documents: ${filteredDocs.length}');
              for (var doc in filteredDocs) {
                print('[DocumentListScreen] Document: ${doc.number}, Type: ${doc.type}, Date: ${doc.date}, Status: ${doc.status}');
              }              return ImprovedBalanceSheetWidget(
                documents: filteredDocs,
                onExportBalanceSheet: _exportDocuments,
              );
            }
            
            return _buildDocumentListView(filteredDocs);
          }).toList(),
        );
      },
    );
  }

  Widget _buildDocumentListView(List<Document> documents) {
    if (documents.isEmpty) {
      return const Center(
        child: Text("Nenhum documento encontrado nesta categoria."),
      );
    }

    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (ctx, index) {
        final doc = documents[index];
        return _buildDocumentItem(doc);
      },
    );
  }

  Widget _buildDocumentItem(Document doc) {
    final isSelected = _selectedDocuments.contains(doc.id);
    final formattedDate = doc.date.isNotEmpty 
        ? DateFormat("dd/MM/yyyy").format(DateTime.parse(doc.date))
        : "Data inválida";
    final color = _getDocColor(doc.type, doc.status);

    return InkWell(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(doc.id);
        } else {
          _navigateToDocumentDetail(doc);
        }
      },
      onLongPress: () => _toggleSelection(doc.id),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          border: const Border(
            bottom: BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Vertical highlight bar
            Container(
              width: 4,
              height: 72,
              color: color,
            ),
            const SizedBox(width: 12),
            // Document content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document title and number
                    Text(
                      "Documento #${doc.id}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Date and type
                    Text(
                      "$formattedDate • ${documentTypeToString(doc.type)}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Status/comments
                    Text(
                      doc.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Selection indicator or action button
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: isSelected
                  ? Icon(Icons.check_circle, color: Colors.blue[700])
                  : Icon(Icons.chevron_right, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: const Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,        children: [
          _buildQuickActionButton(
            icon: Icons.play_arrow,
            label: "Processar",
            onPressed: _processSelectedDocuments,
          ),
          _buildQuickActionButton(
            icon: Icons.receipt,
            label: "Recibo",
            onPressed: _generateReceiptForSelected,
          ),
          _buildQuickActionButton(
            icon: Icons.print,
            label: "Imprimir",
            onPressed: _printSelectedDocuments,
          ),
          _buildQuickActionButton(
            icon: Icons.delete,
            label: "Excluir",
            color: Colors.red,
            onPressed: () {
              _confirmDeleteSelected();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? Colors.blue[700],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
      onPressed: () {
        // Determinar o tipo de documento baseado na aba atual
        DocumentType? defaultType;
        final currentTab = _tabFilters[_tabController.index];
        
        switch (currentTab) {
          case 'ENTRADA':
            defaultType = DocumentType.entrada;
            break;
          case 'SAÍDA':
            defaultType = DocumentType.saida;
            break;
          case 'BALANÇA':
            // Para balança, vamos usar entrada como padrão
            defaultType = DocumentType.entrada;
            break;
          default:
            // Para "TODOS", deixar o usuário escolher
            defaultType = null;
            break;
        }
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => EditDocumentScreen(defaultType: defaultType),
          ),
        );
      },
    );
  }

  void _navigateToDocumentDetail(Document doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DocumentDetailScreen(documentId: int.parse(doc.id)),
      ),
    );
  }

  Future<void> _confirmDeleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Exclusão"),
        content: Text(
          "Tem certeza que deseja excluir ${_selectedDocuments.length} documento(s)? "
          "Isso reverterá os movimentos de estoque associados.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              "Excluir",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final docProvider = Provider.of<DocumentProvider>(context, listen: false);
        for (final docId in _selectedDocuments) {
          await docProvider.cancelDocument(int.parse(docId));
        }
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(
            context,
            "${_selectedDocuments.length} documento(s) cancelado(s)!",
          );
        }
        _clearSelection();
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, "Erro ao cancelar: $e");
        }
      }
    }
  }
}
