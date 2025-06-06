// frontend/lib/screens/edit_document_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/document_model.dart' as doc_model;
import '../models/customer_model.dart';
import '../models/supplier_model.dart';
import '../models/stock_item.dart';
import '../providers/document_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/store_provider.dart';
import '../widgets/app_drawer.dart';
import '../utils/error_handler.dart';

class EditDocumentScreen extends StatefulWidget {
  final String? documentId;

  const EditDocumentScreen({super.key, this.documentId});

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
  doc_model.DocumentType _selectedType = doc_model.DocumentType.entrada;
  DateTime _selectedDate = DateTime.now();
  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;
  StockItem? _selectedStockItem;

  final List<doc_model.DocumentItem> _items = [];
  bool _isLoading = false;
  final bool _isSaving = false;

  final _quantityController = TextEditingController(text: "1");
  final _priceController = TextEditingController(text: "0.00");

  final _addItemFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _documentId = widget.documentId;
    if (_documentId != null) {
      _loadDocument();
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
          _referenceController.text = document.reference ?? '';
          _notesController.text = document.notes ?? '';
          _selectedType = document.type;
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
                    if (_selectedType == doc_model.DocumentType.saida && 
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
                  
                  setState(() {
                    _items.add(doc_model.DocumentItem(
                      id: _selectedStockItem!.id.toString(),
                      name: _selectedStockItem!.name,
                      quantity: quantity,
                      price: price,
                      unit: _selectedStockItem!.properties['unit'] ?? 'UN',
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

  void _updateItem(int index, doc_model.DocumentItem item) {
    setState(() {
      _items[index] = item;
    });
  }

  Future<void> _saveDocument() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
      if (storeId == null) {
        throw Exception('Nenhuma loja selecionada');
      }

      final document = doc_model.Document(
        id: _documentId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        number: _numberController.text,
        type: _selectedType,
        date: _dateController.text,
        reference: _referenceController.text,
        notes: _notesController.text,
        items: _items,
        customerId: _selectedCustomer?.id.toString(),
        supplierId: _selectedSupplier?.id.toString(),
        sourceWarehouseId: _selectedSourceWarehouseId?.toString(),
        destinationWarehouseId: _selectedDestinationWarehouseId?.toString(),
        status: 'DRAFT',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final result = _documentId == null
          ? await docProvider.createDocument(document)
          : await docProvider.updateDocument(int.parse(_documentId!), document);      if (!mounted) return;      if (result != null) {
        ErrorHandler.showSuccessSnackBar(context, 'Documento salvo com sucesso!');
        Navigator.of(context).pop();      } else {
        ErrorHandler.showErrorSnackBar(context, 'Erro ao salvar documento: ${docProvider.error}');
      }    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, 'Erro: $e');
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

    // Validações específicas por tipo
    if (_selectedType == doc_model.DocumentType.saida && _selectedCustomer == null) {
      ErrorHandler.showErrorSnackBar(context, 'Selecione um cliente para documentos de saída');
      return;
    }

    if (_selectedType == doc_model.DocumentType.entrada && _selectedSupplier == null) {
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
      final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
      if (storeId == null) {
        throw Exception('Nenhuma loja selecionada');
      }

      // Criar documento com status PROCESSED
      final document = doc_model.Document(
        id: _documentId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        number: _numberController.text.isEmpty 
            ? 'DOC-${DateTime.now().millisecondsSinceEpoch}' 
            : _numberController.text,
        type: _selectedType,
        date: DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD format
        reference: _referenceController.text,
        notes: _notesController.text,
        items: _items,
        customerId: _selectedCustomer?.id.toString(),
        supplierId: _selectedSupplier?.id.toString(),
        sourceWarehouseId: _selectedSourceWarehouseId?.toString(),
        destinationWarehouseId: _selectedDestinationWarehouseId?.toString(),
        status: 'PROCESSED',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );      // Processar documento no backend (que deve atualizar o estoque automaticamente)
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final result = _documentId == null
          ? await docProvider.createDocument(document)
          : await docProvider.updateDocument(int.parse(_documentId!), document);

      if (!mounted) return;

      if (result != null) {
        // Atualizar cache local do estoque
        final stockProvider = Provider.of<StockProvider>(context, listen: false);
        await stockProvider.fetchStockItems(); // Recarrega os itens do estoque

        ErrorHandler.showSuccessSnackBar(context, 'Documento processado com sucesso!');
        Navigator.of(context).pop();
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
  String documentTypeToString(doc_model.DocumentType type) {
    switch (type) {
      case doc_model.DocumentType.entrada:
        return 'Entrada';
      case doc_model.DocumentType.saida:
        return 'Saída';
      case doc_model.DocumentType.transferencia:
        return 'Transferência';
      case doc_model.DocumentType.ajuste:
        return 'Ajuste';
      case doc_model.DocumentType.ajusteEntrada:
        return 'Ajuste Entrada';
      case doc_model.DocumentType.ajusteSaida:
        return 'Ajuste Saída';
      case doc_model.DocumentType.unknown:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_documentId == null ? 'Novo Documento' : 'Editar Documento'),        actions: [
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
                    DropdownButtonFormField<doc_model.DocumentType>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: "Tipo de Documento*"),
                      items: doc_model.DocumentType.values
                          .where((t) => t != doc_model.DocumentType.unknown)
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(documentTypeToString(type)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                            if (_selectedType != doc_model.DocumentType.saida) _selectedCustomer = null;
                            if (_selectedType != doc_model.DocumentType.entrada) _selectedSupplier = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Mostrar dropdown de Cliente apenas para SAIDA
                    if (_selectedType == doc_model.DocumentType.saida)
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
                    if (_selectedType == doc_model.DocumentType.entrada)
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
                    // --- Itens do Documento ---
                    DropdownButtonFormField<StockItem>(
                      value: _selectedStockItem,
                      decoration: const InputDecoration(labelText: "Selecione um item*"),
                      items: Provider.of<StockProvider>(context)
                          .items
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
                            title: Text(item.name),
                            subtitle: Text('${item.quantity} ${item.unit} - R\$ ${item.price.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeItem(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
