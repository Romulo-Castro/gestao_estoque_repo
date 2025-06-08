// frontend/lib/core/presentation/screens/edit_document_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class EditDocumentScreen extends StatefulWidget {
  final String? documentId;
  final DocumentType? defaultType;

  const EditDocumentScreen({super.key, this.documentId, this.defaultType});

  @override
  State<EditDocumentScreen> createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends State<EditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _dateController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _documentId;
  String? _selectedSourceWarehouseId;
  String? _selectedDestinationWarehouseId;
  DocumentType _selectedType = DocumentType.entrada;
  DateTime _selectedDate = DateTime.now();
  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;
  StockItem? _selectedStockItem;

  final List<DocumentItemModel> _items = [];
  bool _isLoading = false;
  final bool _isSaving = false;

  // New variables for adjustment mode
  bool _isAdjustmentMode = false;
  DocumentModel? _baseDocument;

  final _quantityController = TextEditingController(text: "1");
  final _priceController = TextEditingController(text: "0.00");

  final _addItemFormKey = GlobalKey<FormState>();

  // Helper function to convert string to DocumentType
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

  // Helper function to convert DocumentType to string
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

  @override
  void initState() {
    super.initState();
    _documentId = widget.documentId;
    
    // Usar o tipo padrão se fornecido
    if (widget.defaultType != null) {
      _selectedType = widget.defaultType!;
    }
    
    // Initialize data loading
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
  
  void _initializeFromBaseDocument() {
    if (_baseDocument == null) return;
    
    setState(() {
      // Set the document type to be the same as the base
      _selectedType = _parseDocumentType(_baseDocument!.type);
      
      // Set the customer or supplier - will be handled when data loads
      
      // Copy items from base document
      _items.clear();
      _items.addAll(_baseDocument!.items);
      
      // Update date to today for the adjustment
      _selectedDate = DateTime.now();
      _dateController.text = "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
      
      // Add note indicating this is an adjustment
      if (_notesController.text.isEmpty) {
        _notesController.text = "Ajuste baseado no documento #${_baseDocument!.number}";
      }
    });
  }

  Future<void> _initializeData() async {
    // Load necessary data for document creation
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    
    if (storeProvider.selectedStoreId != null) {
      // Set store ID for all providers first
      stockProvider.setStoreId(storeProvider.selectedStoreId);
      customerProvider.setStoreId(storeProvider.selectedStoreId);
      supplierProvider.setStoreId(storeProvider.selectedStoreId);
      
      // Load stock items for item selection (will happen automatically via setStoreId)
      // await stockProvider.fetchStockItems(); // No longer needed since setStoreId calls it
      
      // Load customers and suppliers for document creation (will happen automatically via setStoreId)
      // await customerProvider.fetchCustomers();
      // await supplierProvider.fetchSuppliers();
    }
    
    // Load document if editing
    if (_documentId != null) {
      await _loadDocument();
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
    super.dispose();
  }

  Future<void> _loadDocument() async {
    if (_documentId == null) return;

    setState(() => _isLoading = true);

    try {      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final document = await docProvider.fetchDocumentById(int.parse(_documentId!));

      if (document != null) {
        setState(() {
          _numberController.text = document.number;
          _dateController.text = document.date;
          // Note: DocumentModel doesn't have reference and notes fields
          _selectedType = _parseDocumentType(document.type);
          _items.clear();
          _items.addAll(document.items);
        });
      }    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, 'Erro ao carregar documento: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }  void _addItem() {
    if (_selectedStockItem == null) {
      ErrorHandler.showErrorSnackBar(context, 'Selecione um item primeiro');
      return;
    }

    _showAddItemDialog();
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar ${_selectedStockItem!.name}'),
          content: Form(
            key: _addItemFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Item: ${_selectedStockItem!.name}'),
                Text('Disponível: ${_selectedStockItem!.quantity} ${_selectedStockItem!.properties['unit'] ?? 'UN'}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantidade*',
                    suffixText: _selectedStockItem!.properties['unit'] ?? 'UN',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite a quantidade';
                    }
                    final quantity = double.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Quantidade deve ser maior que zero';
                    }
                    // Validar quantidade disponível para saída
                    if (_selectedType == DocumentType.saida && 
                        quantity > _selectedStockItem!.quantity) {
                      return 'Quantidade não disponível em estoque';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Preço Unitário*',
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite o preço';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price < 0) {
                      return 'Preço deve ser maior ou igual a zero';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _quantityController.text = "1";
                _priceController.text = "0.00";
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_addItemFormKey.currentState!.validate()) {
                  final quantity = double.parse(_quantityController.text);
                  final price = double.parse(_priceController.text);
                  
                  // Validation: Ensure the selected stock item has a valid ID
                  if (_selectedStockItem == null || _selectedStockItem!.id <= 0) {
                    ErrorHandler.showErrorSnackBar(context, 'Erro: Item selecionado inválido. Tente selecionar novamente.');
                    return;
                  }
                  
                  setState(() {
                    _items.add(DocumentItemModel(
                      id: null, // Changed from _selectedStockItem!.id
                      quantity: quantity.toInt(),
                      unitValue: price,
                      totalValue: quantity * price,
                      description: _selectedStockItem!.name,
                      stockItemId: _selectedStockItem!.id,
                    ));
                    _selectedStockItem = null;
                  });
                  
                  Navigator.of(context).pop();
                  _quantityController.text = "1";
                  _priceController.text = "0.00";
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, DocumentItemModel item) {
    setState(() {
      _items[index] = item;
    });
  }

  Future<void> _saveDocument() async {
    if (_formKey.currentState?.validate() == false) {
      ErrorHandler.showErrorSnackBar(context, 'Por favor, corrija os erros no formulário.');
      return;
    }
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      if (storeProvider.selectedStoreId == null) {
        throw Exception('Nenhuma loja selecionada para salvar o rascunho.');
      }

      double totalValue = _items.fold(0.0, (sum, item) => sum + item.totalValue);
      String documentDate = DateTime.now().toIso8601String().split('T')[0];
      // Attempt to parse date from controller if available and valid
      if (_dateController.text.isNotEmpty) {
        try {
          // Assuming _dateController.text is in "dd/MM/yyyy" format as used in _presentDatePicker logic
          // This part needs a robust date parsing, ideally aligning with how _selectedDate is set.
          // For simplicity, if _selectedDate is already set, use it. Otherwise, parse or default.
          final parts = _dateController.text.split('/');
          if (parts.length == 3) {
            final day = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            final year = int.tryParse(parts[2]);
            if (day != null && month != null && year != null) {
              documentDate = DateTime(year, month, day).toIso8601String().split('T')[0];
            }
          }
        } catch (e) {
          // Ignore parsing error, use current date
          debugPrint("Error parsing date from _dateController for draft: $e");
        }
      }


      final document = DocumentModel(
        id: _documentId != null ? int.tryParse(_documentId!) : null,
        number: _numberController.text.isEmpty
            ? 'DRAFT-${DateTime.now().millisecondsSinceEpoch}'
            : _numberController.text,
        type: _documentTypeToString(_selectedType),
        description: _notesController.text.isNotEmpty ? _notesController.text : "Rascunho de Documento",
        totalValue: totalValue,
        date: documentDate,
        status: 'DRAFT', // Save as DRAFT
        storeId: storeProvider.selectedStoreId!,
        items: _items,
        // Optional: include _selectedCustomer?.id or _selectedSupplier?.id if your backend handles them for drafts
      );

      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      
      // If _documentId exists and we are saving a draft, it's an update to that draft.
      // Otherwise, it's a new draft.
      final bool isUpdatingExistingDraft = _documentId != null;
      
      DocumentModel? result;
      if (isUpdatingExistingDraft) {
        result = await docProvider.updateDocument(int.parse(_documentId!), document);
      } else {
        result = await docProvider.createDocument(document);
      }

      if (!mounted) return;

      if (result != null) {
        ErrorHandler.showSuccessSnackBar(context, 'Rascunho salvo com sucesso!');
        if (!isUpdatingExistingDraft && result.id != null) {
          // If it was a new draft and successfully created, update the _documentId
          setState(() {
            _documentId = result!.id.toString();
            // Optionally update the number controller if it was auto-generated
            if (_numberController.text.startsWith('DRAFT-')) {
              _numberController.text = result.number;
            }
          });
        }
        // Decide whether to pop or stay. For drafts, usually stay.
        // Navigator.of(context).pop(true); 
      } else {
        ErrorHandler.showErrorSnackBar(context, 'Erro ao salvar rascunho: ${docProvider.error ?? "Erro desconhecido"}');
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, 'Erro ao salvar rascunho: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Processa o documento e atualiza o estoque
  Future<void> _processDocument() async {
    if (!mounted) return;

    // Validação básica
    if (_items.isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'Adicione pelo menos um item ao documento');
      return;
    }

    // VALIDATION: Check if all items have a stockItemId
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      // Ensure stockItemId is not null and not zero (or any other invalid placeholder)
      if (item.stockItemId == null || item.stockItemId == 0) { 
        ErrorHandler.showErrorSnackBar(
          context, 
          'Erro no item ${i + 1} "${item.description}": ID do item de estoque ausente ou inválido. Remova e adicione o item novamente.'
        );
        return;
      }
      
      // Additional validation: ensure the description is not empty
      if (item.description.trim().isEmpty) {
        ErrorHandler.showErrorSnackBar(
          context, 
          'Erro no item ${i + 1}: Descrição do item não pode estar vazia.'
        );
        return;
      }
      
      // Additional validation: ensure positive quantity
      if (item.quantity <= 0) {
        ErrorHandler.showErrorSnackBar(
          context, 
          'Erro no item ${i + 1} "${item.description}": Quantidade deve ser maior que zero.'
        );
        return;
      }
    }

    // Validações específicas por tipo
    if (_selectedType == DocumentType.saida && _selectedCustomer == null) {
      ErrorHandler.showErrorSnackBar(context, 'Selecione um cliente para documentos de saída');
      return;
    }

    if (_selectedType == DocumentType.entrada && _selectedSupplier == null) {
      ErrorHandler.showErrorSnackBar(context, 'Selecione um fornecedor para documentos de entrada');
      return;
    }

    final confirmed = await showDialog<bool>(      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Processar Documento'),
        content: const Text('Confirma o processamento do documento? Esta ação irá atualizar o estoque e não poderá ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Processar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      if (storeProvider.selectedStoreId == null) {
        throw Exception('Nenhuma loja selecionada');
      }

      // Calculate total value
      double totalValue = _items.fold(0.0, (sum, item) => sum + item.totalValue);

      // Criar documento com status PROCESSED
      final document = DocumentModel(
        id: _documentId != null ? int.tryParse(_documentId!) : null,
        number: _numberController.text.isEmpty 
            ? 'DOC-${DateTime.now().millisecondsSinceEpoch}' 
            : _numberController.text,
        type: _documentTypeToString(_selectedType),
        description: "Documento ${_documentTypeToString(_selectedType)} - ${_numberController.text}",
        totalValue: totalValue,
        date: DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD format
        status: 'PROCESSED',
        storeId: storeProvider.selectedStoreId!,
        items: _items,
      );

      // Processar documento no backend (que deve atualizar o estoque automaticamente)
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      
      // For adjustment mode, always create a new document (even if we have a documentId from base)
      final bool shouldCreateNew = _documentId == null || _isAdjustmentMode;
      
      final result = shouldCreateNew
          ? await docProvider.createDocument(document)
          : await docProvider.updateDocument(int.parse(_documentId!), document);

      if (!mounted) return;

      if (result != null) {
        // Atualizar cache local do estoque
        final stockProvider = Provider.of<StockProvider>(context, listen: false);
        final storeProvider = Provider.of<StoreProvider>(context, listen: false);
        
        // Ensure stock provider has the correct store ID before fetching
        if (storeProvider.selectedStoreId != null) {
          stockProvider.setStoreId(storeProvider.selectedStoreId);
        }
        // Note: No need to call fetchStockItems explicitly since setStoreId will trigger it

        final successMessage = _isAdjustmentMode 
          ? 'Ajuste criado com sucesso!' 
          : 'Documento processado com sucesso!';
        ErrorHandler.showSuccessSnackBar(context, successMessage);
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        ErrorHandler.showErrorSnackBar(context, 'Erro ao processar documento: ${docProvider.error}');
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, 'Erro: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper para converter DocumentType para String
  String documentTypeToString(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return 'Entrada';
      case DocumentType.saida:
        return 'Saída';
      case DocumentType.unknown:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdjustmentMode 
          ? 'Criar Ajuste' 
          : (_documentId == null ? 'Novo Documento' : 'Editar Documento')),
        actions: [
          // Refresh stock items button
          Consumer<StockProvider>(
            builder: (context, stockProvider, child) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: stockProvider.isLoading ? null : () {
                final storeProvider = Provider.of<StoreProvider>(context, listen: false);
                if (storeProvider.selectedStoreId != null) {
                  stockProvider.setStoreId(storeProvider.selectedStoreId);
                }
              },
              tooltip: 'Atualizar itens de estoque',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveDocument,
            tooltip: 'Salvar Rascunho',
          ),
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: (_isLoading || _items.isEmpty) ? null : _processDocument,
            tooltip: 'Processar Documento',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // --- Cabeçalho do Documento ---
                    DropdownButtonFormField<DocumentType>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: "Tipo de Documento*"),
                      items: DocumentType.values
                          .where((t) => t != DocumentType.unknown)
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(documentTypeToString(type)),
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
                    // Mostrar dropdown de Cliente apenas para SAIDA
                    if (_selectedType == DocumentType.saida)
                      DropdownButtonFormField<Customer>(
                        value: _selectedCustomer,
                        decoration: const InputDecoration(labelText: "Cliente*"),
                        items: Provider.of<CustomerProvider>(context)
                            .customers
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
                      ),
                    // Mostrar dropdown de Fornecedor apenas para ENTRADA
                    if (_selectedType == DocumentType.entrada)
                      DropdownButtonFormField<Supplier>(
                        value: _selectedSupplier,
                        decoration: const InputDecoration(labelText: "Fornecedor*"),
                        items: Provider.of<SupplierProvider>(context)
                            .suppliers
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
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        hintText: 'Informações adicionais sobre o documento...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // --- Itens do Documento ---
                    Consumer<StockProvider>(
                      builder: (context, stockProvider, child) {
                        if (stockProvider.isLoading) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 16),
                                  Text('Carregando itens...'),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        if (stockProvider.hasError) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text('Erro ao carregar itens: ${stockProvider.error}'),
                                  ElevatedButton(
                                    onPressed: () {
                                      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
                                      if (storeProvider.selectedStoreId != null) {
                                        stockProvider.setStoreId(storeProvider.selectedStoreId);
                                      }
                                    },
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        if (stockProvider.items.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Nenhum item de estoque disponível. Cadastre itens primeiro.'),
                            ),
                          );
                        }
                        
                        return DropdownButtonFormField<StockItem>(
                          value: _selectedStockItem,
                          decoration: const InputDecoration(labelText: "Selecione um item*"),
                          items: stockProvider.items
                              .map((item) => DropdownMenuItem(
                                    value: item,
                                    child: Text("${item.name} (Disp: ${item.quantity})"),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStockItem = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Item'),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.description),
                            subtitle: Text('Quantidade: ${item.quantity} - R\$ ${item.unitValue.toStringAsFixed(2)} cada'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('R\$ ${item.totalValue.toStringAsFixed(2)}', 
                                     style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Show total amount
                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total do Documento:',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'R\$ ${_items.fold(0.0, (sum, item) => sum + item.totalValue).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20, 
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
                ),
              ),
            ),
    );
  }
}
