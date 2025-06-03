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

    try {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final document = await docProvider.fetchDocumentById(_documentId!);

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
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar documento: $e')),
      );
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
  }

  void _addItem() {
    if (_selectedStockItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um item primeiro')),
      );
      return;
    }

    setState(() {
      _items.add(doc_model.DocumentItem(
        id: _selectedStockItem!.id.toString(),
        name: _selectedStockItem!.name,
        quantity: 0,
        price: _selectedStockItem!.price ?? 0,
        unit: _selectedStockItem!.properties['unit'] ?? 'UN',
      ));
      _selectedStockItem = null;
    });
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
      );

      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final success = _documentId == null
          ? await docProvider.createDocument(document)
          : await docProvider.updateDocument(document);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento salvo com sucesso!')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar documento: ${docProvider.error}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
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
        title: Text(_documentId == null ? 'Novo Documento' : 'Editar Documento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveDocument,
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
