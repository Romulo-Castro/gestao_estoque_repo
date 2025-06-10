// frontend/lib/core/presentation/screens/create_document_screen.dart
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

class CreateDocumentScreen extends StatefulWidget {
  final DocumentType? defaultType;

  const CreateDocumentScreen({
    super.key,
    this.defaultType,
  });

  @override
  State<CreateDocumentScreen> createState() => _CreateDocumentScreenState();
}

class _CreateDocumentScreenState extends State<CreateDocumentScreen>
    with TickerProviderStateMixin {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();

  // Document data
  DocumentType _selectedType = DocumentType.entrada;
  DateTime _selectedDate = DateTime.now();
  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;
    // Document items
  final List<DocumentItemModel> _items = [];
  
  // UI state
  bool _isSaving = false;
  bool _showCreateWarning = true;

  // Item addition fields
  StockItem? _selectedStockItem;
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    
    // Set default type from arguments
    if (widget.defaultType != null) {
      _selectedType = widget.defaultType!;
    }

    // Show warning dialog about documents not being editable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showCreateWarning) {
        _showCreateWarningDialog();
      }
    });

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
      if (storeId != null) {
        final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
        final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
        final stockProvider = Provider.of<StockProvider>(context, listen: false);
        
        customerProvider.setStoreId(storeId);
        supplierProvider.setStoreId(storeId);
        stockProvider.setStoreId(storeId);
      }
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showCreateWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
        title: const Text('⚠️ Documentos não podem ser editados'),
        content: const Text(
          'ATENÇÃO: Uma vez criado, um documento não poderá ser editado. '
          'Verifique todas as informações antes de salvar.\n\n'
          'Esta é uma medida de segurança para manter a integridade dos dados.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showCreateWarning = false;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Entendi, continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Novo Documento'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              onPressed: _saveDocument,
              icon: const Icon(Icons.save_as_outlined),
              tooltip: 'Salvar Documento',
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDocumentHeader(),
                    const SizedBox(height: 24),
                    _buildItemsSection(),
                  ],
                ),
              ),
            ),
            _buildTotalSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes do Documento',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                bool useColumnLayout = constraints.maxWidth < 600;
                return Flex(
                  direction: useColumnLayout ? Axis.vertical : Axis.horizontal,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: TextFormField(
                        controller: _numberController,
                        decoration: const InputDecoration(
                          labelText: 'Número do Documento',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                        ),
                        validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
                      ),
                    ),
                    SizedBox(width: useColumnLayout ? 0 : 16, height: useColumnLayout ? 16 : 0),
                    Flexible(
                      child: DropdownButtonFormField<DocumentType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Documento',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.article_outlined),
                        ),
                        items: DocumentType.values
                            .where((type) => type != DocumentType.unknown)
                            .map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getTypeLabel(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                              _selectedCustomer = null;
                              _selectedSupplier = null;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Data de Emissão',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _selectedType == DocumentType.entrada
                  ? _buildSupplierDropdown()
                  : _selectedType == DocumentType.saida
                      ? _buildCustomerDropdown()
                      : const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações Adicionais',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        return DropdownButtonFormField<Customer>(
          value: _selectedCustomer,
          decoration: const InputDecoration(
            labelText: 'Cliente *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: provider.customers.map((customer) {
            return DropdownMenuItem(
              value: customer,
              child: Text(customer.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCustomer = value;
            });
          },
          validator: (value) => value == null ? 'Selecione um cliente' : null,
        );
      },
    );
  }

  Widget _buildSupplierDropdown() {
    return Consumer<SupplierProvider>(
      builder: (context, provider, child) {
        return DropdownButtonFormField<Supplier>(
          value: _selectedSupplier,
          decoration: const InputDecoration(
            labelText: 'Fornecedor *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store_mall_directory_outlined),
          ),
          items: provider.suppliers.map((supplier) {
            return DropdownMenuItem(
              value: supplier,
              child: Text(supplier.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSupplier = value;
            });
          },
          validator: (value) => value == null ? 'Selecione um fornecedor' : null,
        );
      },
    );
  }
  Widget _buildItemsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Itens do Documento',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                label: const Text('Adicionar Item', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 20),
            if (_items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 60, color: Theme.of(context).hintColor),
                      const SizedBox(height: 16),
                      Text('Nenhum item adicionado ainda.', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Clique em "Adicionar Item" para começar.', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) => _buildItemCard(_items[index], index),
                separatorBuilder: (context, index) => const Divider(height: 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(DocumentItemModel item, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _removeItem(index), // Example: long press to remove
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColorLight,
                child: Text(
                  item.stockItemName.isNotEmpty 
                      ? item.stockItemName.substring(0, 1).toUpperCase()
                      : '?',
                  style: TextStyle(color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.stockItemName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      'Qtd: ${item.quantity.toStringAsFixed(2)}  |  Preço Unit.: R\$ ${item.unitValue.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'R\$ ${item.totalValue.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                tooltip: 'Remover Item',
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    final totalValue = _items.fold<double>(0.0, (sum, item) => sum + item.totalValue);
    
    return Material(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SafeArea( // Ensures content is not obscured by system UI like bottom navigation bars
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool useColumnLayout = constraints.maxWidth < 400; // Adjusted breakpoint
              return Flex(
                direction: useColumnLayout ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: useColumnLayout ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                children: [
                  Text(
                    'Total Geral: R\$ ${totalValue.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: useColumnLayout ? 12 : 0, width: useColumnLayout ? 0 : 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveDocument,
                    icon: _isSaving 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isSaving ? 'Salvando...' : 'Concluir e Salvar'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    _selectedStockItem = null;
    _quantityController.clear();
    _priceController.clear();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_box, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Adicionar Item',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer<StockProvider>(
                          builder: (context, stockProvider, child) {
                            if (stockProvider.items.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Nenhum item disponível em estoque'),
                              );
                            }
                            return Theme(
                              data: Theme.of(dialogContext).copyWith(
                                canvasColor: Theme.of(dialogContext).scaffoldBackgroundColor,
                              ),
                              child: DropdownButtonFormField<StockItem>(
                                value: _selectedStockItem,
                                decoration: const InputDecoration(
                                  labelText: 'Selecionar Item do Estoque',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.inventory_2_outlined),
                                ),
                                isExpanded: true,
                                menuMaxHeight: 300,
                                items: stockProvider.items.map((StockItem item) {
                                  return DropdownMenuItem<StockItem>(
                                    value: item,
                                    child: Text(item.name),
                                  );
                                }).toList(),
                                onChanged: (StockItem? value) {
                                  setDialogState(() {
                                    _selectedStockItem = value;
                                  });
                                },
                                  validator: (StockItem? value) =>
                                      value == null ? 'Selecione um item' : null,
                                ),
                              );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantidade',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.format_list_numbered),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Campo obrigatório';
                            if (double.tryParse(value) == null) return 'Número inválido';
                            if (double.parse(value) <= 0) return 'Quantidade deve ser maior que zero';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Preço Unitário (R\$)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money_outlined),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Campo obrigatório';
                            if (double.tryParse(value) == null) return 'Número inválido';
                            if (double.parse(value) < 0) return 'Preço não pode ser negativo';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).scaffoldBackgroundColor,
                    border: Border(top: BorderSide(color: Theme.of(dialogContext).dividerColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          final quantityValid = (_quantityController.text.isNotEmpty && double.tryParse(_quantityController.text) != null && double.parse(_quantityController.text) > 0);
                          final priceValid = (_priceController.text.isNotEmpty && double.tryParse(_priceController.text) != null && double.parse(_priceController.text) >= 0);
                          final itemSelected = _selectedStockItem != null;

                          if (itemSelected && quantityValid && priceValid) {
                            _addItem();
                            Navigator.of(dialogContext).pop();
                          } else {
                             ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor, preencha todos os campos corretamente.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Adicionar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(dialogContext).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  void _addItem() {
    if (_selectedStockItem == null) return;

    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (quantity <= 0 || price < 0) return;

    if (_selectedType == DocumentType.saida) {
      final currentItemQuantity = _items
          .where((item) => item.stockItemId == _selectedStockItem!.id)
          .fold<double>(0.0, (sum, item) => sum + item.quantity);
      
      final totalRequestedQuantity = currentItemQuantity + quantity;
      
      if (totalRequestedQuantity > _selectedStockItem!.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quantidade insuficiente em estoque!\n'
              'Disponível: ${_selectedStockItem!.quantity.toStringAsFixed(0)}, '
              'Já Adicionado: ${currentItemQuantity.toStringAsFixed(0)}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final existingIndex = _items.indexWhere(
      (item) => item.stockItemId == _selectedStockItem!.id,
    );

    setState(() {
      if (existingIndex != -1) {
        final existingItem = _items[existingIndex];
        _items[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
          unitValue: price,
        );
      } else {
        _items.add(DocumentItemModel(
          quantity: quantity,
          unitValue: price,
          stockItemId: _selectedStockItem!.id,
          stockItemName: _selectedStockItem!.name,
        ));
      }
    });
  }

  void _removeItem(int index) {
    showDialog(
      context: context, 
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirmar Remoção'),
        content: Text('Tem certeza que deseja remover "${_items[index].stockItemName}" da lista de itens?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
              Navigator.of(dialogContext).pop(); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item removido com sucesso.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Remover Definitivamente'),
          ),
        ],
      ), 
    ); 
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = DateFormat('dd/MM/yyyy').format(date);
      });
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedType == DocumentType.entrada && _selectedSupplier == null) {
      ErrorHandler.showErrorSnackBar(context, 'Selecione um fornecedor para documentos de entrada');
      return;
    }
    
    if (_selectedType == DocumentType.saida && _selectedCustomer == null) {
      ErrorHandler.showErrorSnackBar(context, 'Selecione um cliente para documentos de saída');
      return;
    }
    
    if (_items.isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'Adicione pelo menos um item ao documento');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
      if (storeId == null) {
        throw Exception('Nenhuma loja selecionada');
      }

      final totalValue = _items.fold<double>(0.0, (sum, item) => sum + item.totalValue);
      final document = DocumentModel(
        number: _numberController.text.trim(),
        type: _getTypeString(_selectedType),
        description: _notesController.text.trim(),
        totalValue: totalValue,
        date: _selectedDate.toIso8601String(),
        storeId: storeId,
        items: _items,
      );

      final provider = Provider.of<DocumentProvider>(context, listen: false);
      await provider.createDocument(document);

      if (mounted) {
        Navigator.of(context).pop();
        ErrorHandler.showSuccessSnackBar(context, 'Documento criado com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Erro ao criar documento: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _getTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return 'Entrada';
      case DocumentType.saida:
        return 'Saída';
      case DocumentType.unknown:
        return 'Desconhecido';
    }
  }

  String _getTypeString(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return 'entrada';
      case DocumentType.saida:
        return 'saida';
      case DocumentType.unknown:
        return 'unknown';
    }
  }
}