// frontend/lib/core/presentation/screens/improved_edit_document_screen.dart
import 'package:flutter/material.dart';
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
import '../../../shared/utils/error_handler.dart';

class ImprovedEditDocumentScreen extends StatefulWidget {
  final String? documentId;
  final DocumentType? defaultType;

  const ImprovedEditDocumentScreen({
    super.key,
    this.documentId,
    this.defaultType,
  });

  @override
  State<ImprovedEditDocumentScreen> createState() => _ImprovedEditDocumentScreenState();
}

class _ImprovedEditDocumentScreenState extends State<ImprovedEditDocumentScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _dateController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _documentId;
  DocumentType _selectedType = DocumentType.entrada;
  DateTime _selectedDate = DateTime.now();
  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;
  StockItem? _selectedStockItem;

  final List<DocumentItemModel> _items = [];
  bool _isLoading = false;
  bool _isAdjustmentMode = false;
  DocumentModel? _baseDocument;

  final _quantityController = TextEditingController(text: "1");
  final _priceController = TextEditingController(text: "0.00");
  final _addItemFormKey = GlobalKey<FormState>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _documentId = widget.documentId;
    _tabController = TabController(length: 3, vsync: this);
    
    if (widget.defaultType != null) {
      _selectedType = widget.defaultType!;
    }
    
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
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
    _numberController.dispose();
    _dateController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Helper functions
  DocumentType _parseDocumentType(String type) {
    switch (type.toLowerCase()) {
      case 'entrada':
        return DocumentType.entrada;
      case 'saida':
        return DocumentType.saida;
      default:
        return DocumentType.unknown;
    }
  }

  String _documentTypeToString(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return 'entrada';
      case DocumentType.saida:
        return 'saida';
      case DocumentType.unknown:
        return 'unknown';
    }
  }

  String _getDocumentTypeDisplayName(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return 'Entrada';
      case DocumentType.saida:
        return 'Saída';
      case DocumentType.unknown:
        return 'Desconhecido';
    }
  }

  IconData _getDocumentTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return Icons.arrow_downward;
      case DocumentType.saida:
        return Icons.arrow_upward;
      case DocumentType.unknown:
        return Icons.help;
    }
  }

  Color _getDocumentTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return Colors.green;
      case DocumentType.saida:
        return Colors.red;
      case DocumentType.unknown:
        return Colors.grey;
    }
  }

  void _initializeFromBaseDocument() {
    if (_baseDocument == null) return;
    
    setState(() {
      _selectedType = _parseDocumentType(_baseDocument!.type);
      _items.clear();
      _items.addAll(_baseDocument!.items);
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      
      if (_notesController.text.isEmpty) {
        _notesController.text = "Ajuste baseado no documento #${_baseDocument!.number}";
      }
    });
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
      
      if (storeProvider.selectedStoreId != null) {
        stockProvider.setStoreId(storeProvider.selectedStoreId);
        customerProvider.setStoreId(storeProvider.selectedStoreId);
        supplierProvider.setStoreId(storeProvider.selectedStoreId);
      }
      
      if (_documentId != null) {
        await _loadDocument();
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Erro ao inicializar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDocument() async {
    if (_documentId == null) return;

    try {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final document = await docProvider.fetchDocumentById(int.parse(_documentId!));

      if (document != null) {
        setState(() {
          _numberController.text = document.number;
          _selectedType = _parseDocumentType(document.type);
          _notesController.text = document.description;
          
          try {
            if (document.date.isNotEmpty) {
              final parsedDate = DateTime.tryParse(document.date);
              if (parsedDate != null) {
                _selectedDate = parsedDate;
                _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
              }
            }
          } catch (e) {
            debugPrint('Erro ao parsear data do documento: $e');
          }
          
          _items.clear();
          _items.addAll(document.items);
        });
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Erro ao carregar documento: $e');
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _getDocumentTypeColor(_selectedType),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  void _addItem() {
    if (_selectedStockItem == null) {
      ErrorHandler.showErrorSnackBar(context, 'Selecione um item primeiro');
      return;
    }

    if (!_addItemFormKey.currentState!.validate()) {
      return;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;    setState(() {
      _items.add(DocumentItemModel(
        id: _selectedStockItem!.id,
        stockItemId: _selectedStockItem!.id,
        stockItemName: _selectedStockItem!.name,
        quantity: quantity,
        unitValue: price,
      ));
      _selectedStockItem = null;
      _quantityController.text = "1";
      _priceController.text = "0.00";
    });

    ErrorHandler.showSuccessSnackBar(context, 'Item adicionado com sucesso!');
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    ErrorHandler.showSuccessSnackBar(context, 'Item removido!');
  }

  void _updateItemQuantity(int index, double quantity) {
    setState(() {
      _items[index] = _items[index].copyWith(quantity: quantity);
    });
  }

  void _updateItemPrice(int index, double price) {
    setState(() {
      _items[index] = _items[index].copyWith(unitValue: price);
    });
  }

  double get _totalValue {
    return _items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitValue));
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_items.isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'Adicione pelo menos um item ao documento');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      if (storeProvider.selectedStoreId == null) {
        throw Exception('Nenhuma loja selecionada');
      }

      final document = DocumentModel(
        id: _documentId != null ? int.tryParse(_documentId!) : null,
        number: _numberController.text.isEmpty 
            ? 'DOC-${DateTime.now().millisecondsSinceEpoch}' 
            : _numberController.text,
        type: _documentTypeToString(_selectedType),
        description: _notesController.text.isNotEmpty 
            ? _notesController.text 
            : "Documento ${_getDocumentTypeDisplayName(_selectedType)}",
        totalValue: _totalValue,
        date: _selectedDate.toIso8601String().split('T')[0],
        status: 'PROCESSED',
        storeId: storeProvider.selectedStoreId!,
        items: _items,
      );

      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final shouldCreateNew = _documentId == null || _isAdjustmentMode;
      
      final result = shouldCreateNew
          ? await docProvider.createDocument(document)
          : await docProvider.updateDocument(int.parse(_documentId!), document);

      if (!mounted) return;

      if (result != null) {
        final stockProvider = Provider.of<StockProvider>(context, listen: false);
        if (storeProvider.selectedStoreId != null) {
          stockProvider.setStoreId(storeProvider.selectedStoreId);
        }

        final successMessage = _isAdjustmentMode 
          ? 'Ajuste criado com sucesso!' 
          : 'Documento processado com sucesso!';
        ErrorHandler.showSuccessSnackBar(context, successMessage);
        Navigator.of(context).pop(true);
      } else {
        ErrorHandler.showErrorSnackBar(context, 'Erro ao processar documento: ${docProvider.error}');
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Erro: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildHeaderStep() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getDocumentTypeIcon(_selectedType),
                  color: _getDocumentTypeColor(_selectedType),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Informações do Documento',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _getDocumentTypeColor(_selectedType),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Document Type Selection
            DropdownButtonFormField<DocumentType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: "Tipo de Documento*",
                prefixIcon: Icon(_getDocumentTypeIcon(_selectedType)),
                border: const OutlineInputBorder(),
              ),
              items: DocumentType.values
                  .where((t) => t != DocumentType.unknown)
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getDocumentTypeIcon(type), size: 20),
                            const SizedBox(width: 8),
                            Text(_getDocumentTypeDisplayName(type)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    if (_selectedType != DocumentType.saida) _selectedCustomer = null;
                    if (_selectedType != DocumentType.entrada) _selectedSupplier = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Document Number
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: "Número do Documento",
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
                helperText: "Deixe vazio para gerar automaticamente",
              ),
            ),
            const SizedBox(height: 16),
            
            // Date Selection
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: "Data*",
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: _selectDate,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Data é obrigatória';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Customer/Supplier Selection
            if (_selectedType == DocumentType.saida)
              Consumer<CustomerProvider>(
                builder: (ctx, customerProvider, _) => DropdownButtonFormField<Customer>(
                  value: _selectedCustomer,
                  decoration: const InputDecoration(
                    labelText: "Cliente*",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  items: customerProvider.customers
                      .map((customer) => DropdownMenuItem(
                            value: customer,
                            child: Text(customer.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCustomer = value;
                    });
                  },
                  validator: (value) {
                    if (_selectedType == DocumentType.saida && value == null) {
                      return 'Cliente é obrigatório para saída';
                    }
                    return null;
                  },
                ),
              ),
            
            if (_selectedType == DocumentType.entrada)
              Consumer<SupplierProvider>(
                builder: (ctx, supplierProvider, _) => DropdownButtonFormField<Supplier>(
                  value: _selectedSupplier,
                  decoration: const InputDecoration(
                    labelText: "Fornecedor*",
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  items: supplierProvider.suppliers
                      .map((supplier) => DropdownMenuItem(
                            value: supplier,
                            child: Text(supplier.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSupplier = value;
                    });
                  },
                  validator: (value) {
                    if (_selectedType == DocumentType.entrada && value == null) {
                      return 'Fornecedor é obrigatório para entrada';
                    }
                    return null;
                  },
                ),
              ),
              
            const SizedBox(height: 16),
            
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: "Observações",
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Item Section
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _addItemFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_box, color: Colors.blue, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'Adicionar Item',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  // Item Selection
                  Consumer<StockProvider>(
                    builder: (ctx, stockProvider, _) => DropdownButtonFormField<StockItem>(
                      value: _selectedStockItem,
                      decoration: const InputDecoration(
                        labelText: "Selecione um item*",
                        prefixIcon: Icon(Icons.inventory),
                        border: OutlineInputBorder(),
                      ),
                      items: stockProvider.items
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name),
                                    Text(
                                      'Estoque: ${item.quantity}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStockItem = value;
                          if (value != null) {
                            _priceController.text = (value.price ?? 0.0).toStringAsFixed(2);
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione um item';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      // Quantity Input
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: "Quantidade*",
                            prefixIcon: Icon(Icons.numbers),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Quantidade obrigatória';
                            }
                            final quantity = double.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Quantidade inválida';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Price Input
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: "Preço Unitário*",
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Preço obrigatório';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price < 0) {
                              return 'Preço inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Item'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Items List
        if (_items.isNotEmpty) ...[
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list, color: Colors.orange, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'Itens do Documento (${_items.length})',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final total = item.quantity * item.unitValue;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getDocumentTypeColor(_selectedType),
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          item.stockItemName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Qtd: ${item.quantity}'),
                            Text('Preço Unit.: R\$ ${item.unitValue.toStringAsFixed(2)}'),
                            Text(
                              'Total: R\$ ${total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                              onTap: () => _showEditItemDialog(index),
                            ),
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Remover', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                              onTap: () => _removeItem(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const Divider(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getDocumentTypeColor(_selectedType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total do Documento:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'R\$ ${_totalValue.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: _getDocumentTypeColor(_selectedType),
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
        ] else ...[
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
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
                      'Adicione pelo menos um item para continuar',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryStep() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize,
                  color: _getDocumentTypeColor(_selectedType),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Resumo do Documento',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _getDocumentTypeColor(_selectedType),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            _buildSummaryRow('Tipo:', _getDocumentTypeDisplayName(_selectedType)),
            _buildSummaryRow('Número:', _numberController.text.isEmpty ? 'Auto-gerado' : _numberController.text),
            _buildSummaryRow('Data:', _dateController.text),
            
            if (_selectedCustomer != null)
              _buildSummaryRow('Cliente:', _selectedCustomer!.name),
            
            if (_selectedSupplier != null)
              _buildSummaryRow('Fornecedor:', _selectedSupplier!.name),
            
            if (_notesController.text.isNotEmpty)
              _buildSummaryRow('Observações:', _notesController.text),
            
            const SizedBox(height: 16),
            
            Text(
              'Itens (${_items.length}):',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
              ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final total = item.quantity * item.unitValue;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: _getDocumentTypeColor(_selectedType),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.stockItemName} - Qtd: ${item.quantity} x R\$ ${item.unitValue.toStringAsFixed(2)} = R\$ ${total.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            const Divider(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getDocumentTypeColor(_selectedType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total do Documento:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'R\$ ${_totalValue.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _getDocumentTypeColor(_selectedType),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(int index) {
    final item = _items[index];
    final quantityController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.unitValue.toStringAsFixed(2));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${item.stockItemName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: "Quantidade",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: "Preço Unitário",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(quantityController.text) ?? item.quantity;
              final price = double.tryParse(priceController.text) ?? item.unitValue;
              
              _updateItemQuantity(index, quantity);
              _updateItemPrice(index, price);
              
              Navigator.of(context).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_documentId == null ? 'Novo Documento' : 'Editar Documento'),
        backgroundColor: _getDocumentTypeColor(_selectedType),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.info),
              text: 'Cabeçalho',
            ),
            Tab(
              icon: Icon(Icons.list),
              text: 'Itens',
            ),
            Tab(
              icon: Icon(Icons.summarize),
              text: 'Resumo',
            ),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildHeaderStep(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildItemsStep(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildSummaryStep(),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveDocument,
        backgroundColor: _getDocumentTypeColor(_selectedType),
        icon: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isLoading ? 'Processando...' : 'Salvar Documento'),
      ),
    );
  }
}
