// frontend/lib/core/presentation/screens/refactored_edit_document_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/document_entity.dart';
import '../../data/models/document_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/stock_item.dart';
import '../providers/document_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/store_provider.dart';
import '../widgets/app_drawer.dart';

class RefactoredEditDocumentScreen extends StatefulWidget {
  final String? documentId;
  final DocumentType? defaultType;

  const RefactoredEditDocumentScreen({
    super.key,
    this.documentId,
    this.defaultType,
  });

  @override
  State<RefactoredEditDocumentScreen> createState() => _RefactoredEditDocumentScreenState();
}

class _RefactoredEditDocumentScreenState extends State<RefactoredEditDocumentScreen>
    with TickerProviderStateMixin {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _dateController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  // Document data
  String? _documentId;
  DocumentType _selectedType = DocumentType.entrada;
  DateTime _selectedDate = DateTime.now();
  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;
  
  // Document items
  final List<DocumentItemModel> _items = [];
  
  // UI state
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditMode = false;
  
  // Adjustment mode
  bool _isAdjustmentMode = false;
  DocumentModel? _baseDocument;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // Date formatter
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  
  // Add item dialog controllers
  StockItem? _selectedStockItem;
  final _quantityController = TextEditingController(text: "1");
  final _priceController = TextEditingController(text: "0.00");
  final _addItemFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _documentId = widget.documentId;
    _isEditMode = _documentId != null;
    
    // Set default type
    if (widget.defaultType != null) {
      _selectedType = widget.defaultType!;
    }
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
    
    // Initialize date
    _selectedDate = DateTime.now();
    _dateController.text = _dateFormatter.format(_selectedDate);
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    
    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Handle route arguments for adjustment mode
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      final mode = arguments['mode'] as String?;
      final baseDocument = arguments['baseDocument'] as DocumentModel?;
      
      if (mode == 'adjustment' && baseDocument != null) {
        _isAdjustmentMode = true;
        _baseDocument = baseDocument;
        _initializeFromBaseDocument();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _numberController.dispose();
    _dateController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _initializeFromBaseDocument() {
    if (_baseDocument == null) return;
    
    setState(() {
      _selectedType = _parseDocumentType(_baseDocument!.type);
      _items.clear();
      _items.addAll(_baseDocument!.items);
      _selectedDate = DateTime.now();
      _dateController.text = _dateFormatter.format(_selectedDate);
      
      if (_notesController.text.isEmpty) {
        _notesController.text = "Ajuste baseado no documento #${_baseDocument!.number}";
      }
    });
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      
      if (storeProvider.selectedStoreId != null) {
        // Set store ID for all providers
        final stockProvider = Provider.of<StockProvider>(context, listen: false);
        final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
        final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
        
        stockProvider.setStoreId(storeProvider.selectedStoreId);
        customerProvider.setStoreId(storeProvider.selectedStoreId);
        supplierProvider.setStoreId(storeProvider.selectedStoreId);
        
        // If editing, load document data
        if (_isEditMode && _documentId != null) {
          await _loadDocumentData();
        }
      }
    } catch (e) {
      _showErrorDialog('Erro ao inicializar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }  Future<void> _loadDocumentData() async {    try {
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      await documentProvider.fetchDocumentById(int.parse(_documentId!));
      
      final document = documentProvider.currentDocument;
      if (document != null) {
        setState(() {
          _numberController.text = document.number;
          _selectedType = _parseDocumentType(document.type);
          _notesController.text = document.description;
          _items.clear();
          _items.addAll(document.items);
          
          try {
            _selectedDate = DateTime.parse(document.date);
            _dateController.text = _dateFormatter.format(_selectedDate);
          } catch (e) {
            _selectedDate = DateTime.now();
            _dateController.text = _dateFormatter.format(_selectedDate);
          }
        });
      }
    } catch (e) {
      _showErrorDialog('Erro ao carregar documento: $e');
    }
  }

  DocumentType _parseDocumentType(String type) {
    switch (type.toLowerCase()) {
      case 'entrada':
        return DocumentType.entrada;
      case 'saida':
      case 'saída':
        return DocumentType.saida;
      default:
        return DocumentType.entrada;
    }
  }

  String _documentTypeToString(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return 'entrada';
      case DocumentType.saida:
        return 'saida';
      case DocumentType.unknown:
        return 'entrada';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: _isLoading ? _buildLoadingIndicator() : _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isEditMode 
          ? 'Editar Documento' 
          : _isAdjustmentMode 
            ? 'Criar Ajuste'
            : 'Novo Documento',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      actions: [
        if (_items.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveDocument,
            tooltip: 'Salvar documento',
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando...'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDocumentInfoCard(),
                const SizedBox(height: 16),
                _buildItemsCard(),
                const SizedBox(height: 16),
                _buildSummaryCard(),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informações do Documento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDocumentTypeSelector(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNumberField(),
            const SizedBox(height: 16),
            _buildNotesField(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypeSelector() {
    return DropdownButtonFormField<DocumentType>(
      value: _selectedType,
      decoration: const InputDecoration(
        labelText: 'Tipo de Documento',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: DocumentType.values.where((type) => type != DocumentType.unknown).map((type) {
        return DropdownMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(
                type == DocumentType.entrada ? Icons.arrow_downward : Icons.arrow_upward,
                color: type == DocumentType.entrada ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                type == DocumentType.entrada ? 'Entrada' : 'Saída',
                style: TextStyle(
                  color: type == DocumentType.entrada ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedType = value);
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Selecione o tipo de documento';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dateController,
      decoration: const InputDecoration(
        labelText: 'Data',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: _selectDate,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione uma data';
        }
        return null;
      },
    );
  }

  Widget _buildNumberField() {
    return TextFormField(
      controller: _numberController,
      decoration: const InputDecoration(
        labelText: 'Número do Documento',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.tag),
        hintText: 'Ex: DOC-001',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Digite o número do documento';
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Observações',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.notes),
        hintText: 'Observações sobre o documento...',
      ),
      maxLines: 3,
    );
  }

  Widget _buildItemsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.list_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Itens do Documento',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text('${_items.length} itens'),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_items.isEmpty)
              _buildEmptyItemsPlaceholder()
            else
              _buildItemsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItemsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum item adicionado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão + para adicionar itens',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: _items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildItemCard(item, index);
      }).toList(),
    );
  }

  Widget _buildItemCard(DocumentItemModel item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.stockItemName.isNotEmpty ? item.stockItemName : 'Item ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Qtd: ${item.quantity.toStringAsFixed(0)}'),
            Text('Valor Unit.: R\$ ${item.unitValue.toStringAsFixed(2)}'),
            if (item.description.isNotEmpty)
              Text('Obs: ${item.description}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'R\$ ${item.totalValue.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editItem(index);
                    break;
                  case 'delete':
                    _removeItem(index);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remover', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalValue = _items.fold<double>(0, (sum, item) => sum + item.totalValue);
    
    return Card(
      elevation: 3,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resumo do Documento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total de Itens:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  '${_items.length}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Valor Total:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'R\$ ${totalValue.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddItemDialog,
      icon: const Icon(Icons.add),
      label: const Text('Adicionar Item'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _dateFormatter.format(picked);
      });
    }
  }

  void _showAddItemDialog() {
    _selectedStockItem = null;
    _quantityController.text = "1";
    _priceController.text = "0.00";
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adicionar Item'),
          content: Form(
            key: _addItemFormKey,
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStockItemSelector(setDialogState),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantidade',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite a quantidade';
                            }
                            final quantity = double.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Quantidade inválida';
                            }
                            return null;
                          },
                          onChanged: (value) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Preço Unit.',
                            border: OutlineInputBorder(),
                            prefixText: 'R\$ ',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite o preço';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price < 0) {
                              return 'Preço inválido';
                            }
                            return null;
                          },
                          onChanged: (value) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_quantityController.text.isNotEmpty && _priceController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'R\$ ${_calculateItemTotal()}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _updateItemInList(index),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockItemSelector(StateSetter setDialogState) {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        if (stockProvider.isLoading) {
          return const CircularProgressIndicator();
        }
        
        return DropdownButtonFormField<StockItem>(
          value: _selectedStockItem,
          decoration: const InputDecoration(
            labelText: 'Item do Estoque',
            border: OutlineInputBorder(),
          ),
          hint: const Text('Selecione um item'),
          items: stockProvider.items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Estoque: ${item.quantity}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),          onChanged: (value) {
            setDialogState(() {
              _selectedStockItem = value;
              if (value != null) {
                _priceController.text = (value.properties['price'] ?? 0.0).toStringAsFixed(2);
              }
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Selecione um item';
            }
            return null;
          },
        );
      },
    );
  }

  String _calculateItemTotal() {
    final quantityText = _quantityController.text;
    final priceText = _priceController.text;

    // Allow comma or dot as decimal separator for parsing quantity, default to 0 if not parseable
    final quantity = double.tryParse(quantityText.replaceAll(',', '.')) ?? 0.0;
    // Allow comma or dot as decimal separator for parsing price, default to 0 if not parseable
    final price = double.tryParse(priceText.replaceAll(',', '.')) ?? 0.0;
    
    final total = quantity * price;
    // Format with comma for display
    return total.toStringAsFixed(2).replaceAll('.', ',');
  }

  void _addItem() {
    if (_addItemFormKey.currentState?.validate() ?? false) {
      final quantity = double.parse(_quantityController.text);
      final unitValue = double.parse(_priceController.text);
      
      final newItem = DocumentItemModel(
        quantity: quantity,
        unitValue: unitValue,
        stockItemId: _selectedStockItem?.id,
        stockItemName: _selectedStockItem?.name ?? '',
        description: '',
      );
      
      setState(() {
        _items.add(newItem);
      });
      
      Navigator.of(context).pop();
      _showSnackBar('Item adicionado com sucesso!');
    }
  }

  void _updateItemInList(int index) {
    if (_addItemFormKey.currentState?.validate() ?? false) {
      final quantity = double.parse(_quantityController.text);
      final unitValue = double.parse(_priceController.text);
      final originalItem = _items[index]; // Get the original item

      int? newStockItemId;
      String newStockItemName;

      if (_selectedStockItem != null) {
        // A stock item is selected in the dialog (either pre-filled and kept, or newly selected)
        newStockItemId = _selectedStockItem!.id;
        newStockItemName = _selectedStockItem!.name;
      } else {
        // No stock item is selected in the dialog.
        // This means the dropdown was blank (either original item had no stock_item_id,
        // or its stock_item_id didn't match any available stock items from the provider)
        // AND the user did not pick a new stock item.
        // In this case, preserve the original stock item details.
        newStockItemId = originalItem.stockItemId;
        newStockItemName = originalItem.stockItemName;
      }

      final updatedItem = DocumentItemModel(
        id: originalItem.id, // Preserve original item ID if it exists
        quantity: quantity,
        unitValue: unitValue,
        stockItemId: newStockItemId,
        stockItemName: newStockItemName,
        description: originalItem.description, // Preserve original description for now
      );

      setState(() {
        _items[index] = updatedItem;
      });

      Navigator.of(context).pop();
      _showSnackBar('Item atualizado com sucesso!');
    }
  }

  void _editItem(int index) {
    final item = _items[index];
    _selectedStockItem = null; 
    // Quantity is likely integer, ensure it's displayed as such.
    _quantityController.text = item.quantity.toInt().toString(); 
    // Price should be formatted with comma for display consistency.
    _priceController.text = item.unitValue.toStringAsFixed(2).replaceAll('.', ',');

    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    if (item.stockItemId != null) {
      try {
        _selectedStockItem = stockProvider.items.firstWhere(
          (stockItem) => stockItem.id == item.stockItemId,
        );
      } catch (e) {
        // Handled in _updateItemInList
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Item'),
          content: Form(
            key: _addItemFormKey, 
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStockItemSelector(setDialogState),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantidade',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite a quantidade';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Quantidade inválida';
                            }
                            return null;
                          },
                          onChanged: (value) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Preço Unit.',
                            border: OutlineInputBorder(),
                            prefixText: 'R\$ ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\\d*[,.]?\\d{0,2}'))],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite o preço';
                            }
                            final price = double.tryParse(value.replaceAll(',', '.'));
                            if (price == null || price < 0) {
                              return 'Preço inválido';
                            }
                            return null;
                          },
                          onChanged: (value) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_quantityController.text.isNotEmpty && _priceController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'R\$ ${_calculateItemTotal()}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _updateItemInList(index), 
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Item'),
        content: const Text('Tem certeza que deseja remover este item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
              Navigator.of(context).pop();
              _showSnackBar('Item removido com sucesso!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Por favor, corrija os erros no formulário');
      return;
    }
    
    if (_items.isEmpty) {
      _showSnackBar('Adicione pelo menos um item ao documento');
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      if (storeProvider.selectedStoreId == null) {
        throw Exception('Nenhuma loja selecionada');
      }
      
      final document = DocumentModel(
        id: _isEditMode ? int.tryParse(_documentId!) : null,
        number: _numberController.text.trim(),
        type: _documentTypeToString(_selectedType),
        description: _notesController.text.trim(),
        totalValue: _items.fold<double>(0, (sum, item) => sum + item.totalValue),
        date: _selectedDate.toIso8601String(),
        status: 'ATIVO',
        storeId: storeProvider.selectedStoreId!,
        items: _items,
      );      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
        if (_isEditMode) {
        await documentProvider.updateDocument(int.parse(_documentId!), document);
        _showSnackBar('Documento atualizado com sucesso!');
      } else {
        await documentProvider.createDocument(document);
        _showSnackBar('Documento criado com sucesso!');
      }
      
      Navigator.of(context).pop(true);
      
    } catch (e) {
      _showErrorDialog('Erro ao salvar documento: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
