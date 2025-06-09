// frontend/lib/core/presentation/screens/create_document_screen.dart
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
import '../widgets/improved_dropdown.dart';
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
        title: const Text('Criar Documento'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _saveDocument,
              icon: const Icon(Icons.save),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações do Documento',
              style: Theme.of(context).textTheme.titleLarge,
            ),            const SizedBox(height: 16),
            // Use Wrap para permitir quebra de linha em telas pequenas
            LayoutBuilder(
              builder: (context, constraints) {
                // Em telas pequenas (< 600px), mostrar campos verticalmente
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      TextFormField(
                        controller: _numberController,
                        decoration: const InputDecoration(
                          labelText: 'Número',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<DocumentType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        items: DocumentType.values
                            .where((type) => type != DocumentType.unknown) // Remove tipo desconhecido
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
                              // Limpar seleções quando o tipo mudar
                              _selectedCustomer = null;
                              _selectedSupplier = null;
                            });
                          }
                        },
                      ),
                    ],
                  );
                } else {
                  // Em telas maiores, mostrar lado a lado
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _numberController,
                          decoration: const InputDecoration(
                            labelText: 'Número',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 16),                      Expanded(
                        child: DropdownButtonFormField<DocumentType>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: DocumentType.values
                              .where((type) => type != DocumentType.unknown) // Remove tipo desconhecido
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
                                // Limpar seleções quando o tipo mudar
                                _selectedCustomer = null;
                                _selectedSupplier = null;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Data',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selectDate,
            ),            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                // Para documentos de entrada, mostrar apenas fornecedor
                if (_selectedType == DocumentType.entrada) {
                  return _buildSupplierDropdown();
                }
                // Para documentos de saída, mostrar apenas cliente
                else if (_selectedType == DocumentType.saida) {
                  return _buildCustomerDropdown();
                }
                // Para tipos desconhecidos ou outros, não mostrar nada
                else {
                  return const SizedBox.shrink();
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Em telas pequenas (< 600px), mostrar título e botão verticalmente
                if (constraints.maxWidth < 600) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Itens do Documento',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showAddItemDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Item'),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Em telas maiores, mostrar lado a lado
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Itens do Documento',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Item'),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            if (_items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Nenhum item adicionado'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) => _buildItemCard(_items[index], index),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(DocumentItemModel item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(item.stockItemName.isNotEmpty 
              ? item.stockItemName.substring(0, 1).toUpperCase()
              : '?'),
        ),
        title: Text(item.stockItemName),
        subtitle: Text(
          'Qtd: ${item.quantity.toStringAsFixed(2)} | '
          'Preço: R\$ ${item.unitValue.toStringAsFixed(2)} | '
          'Total: R\$ ${item.totalValue.toStringAsFixed(2)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeItem(index),
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    final totalValue = _items.fold<double>(0.0, (sum, item) => sum + item.totalValue);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),      child: LayoutBuilder(
        builder: (context, constraints) {
          // Em telas pequenas (< 600px), mostrar total e botão verticalmente
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                Text(
                  'Total: R\$ ${totalValue.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveDocument,
                    icon: _isSaving 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Salvando...' : 'Salvar'),
                  ),
                ),
              ],
            );
          } else {
            // Em telas maiores, mostrar lado a lado
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: R\$ ${totalValue.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveDocument,
                  icon: _isSaving 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Salvando...' : 'Salvar'),
                ),
              ],
            );
          }
        },
      ),
    );
  }  void _showAddItemDialog() {
    _selectedStockItem = null;
    _quantityController.clear();
    _priceController.clear();

    showDialog(
      context: context,
      barrierDismissible: true, // Permite fechar o diálogo clicando fora
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Bordas arredondadas
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 500, // Maximum width for better UX
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
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
                        onPressed: () => Navigator.of(context).pop(),
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
                            
                            // Usando Theme para garantir cores e comportamento consistentes
                            return Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: Theme.of(context).scaffoldBackgroundColor,
                              ),
                              child: DropdownButtonFormField<StockItem>(
                                value: _selectedStockItem,
                                decoration: const InputDecoration(
                                  labelText: 'Selecione um Item *',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                isExpanded: true,
                                menuMaxHeight: 300, // Aumentar altura para melhor visualização
                                dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                                alignment: AlignmentDirectional.centerStart,
                                items: stockProvider.items.map((item) {
                                  final isLowStock = item.quantity < 5;
                                  return DropdownMenuItem(
                                    value: item,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Estoque: ${item.quantity.toStringAsFixed(0)}${isLowStock ? ' (Baixo)' : ''}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isLowStock ? Colors.red : Colors.grey[600],
                                              fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    _selectedStockItem = value;
                                    if (value != null && value.price != null) {
                                      _priceController.text = value.price!.toStringAsFixed(2);
                                    }
                                  });
                                },
                                validator: (value) => value == null ? 'Selecione um item' : null,
                              ),
                            );
                          },
                        ),
                        // Adicionando espaço extra depois do dropdown para evitar problemas de overlay
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: 'Quantidade *',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixText: _selectedStockItem != null 
                                ? 'Máx: ${_selectedStockItem!.quantity.toStringAsFixed(0)}'
                                : null,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Digite a quantidade';
                            final quantity = double.tryParse(value);
                            if (quantity == null || quantity <= 0) return 'Quantidade deve ser maior que zero';
                            if (_selectedStockItem != null && _selectedType == DocumentType.saida) {
                              if (quantity > _selectedStockItem!.quantity) {
                                return 'Quantidade maior que estoque disponível';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Preço Unitário *',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            prefixText: 'R\$ ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Digite o preço';
                            final price = double.tryParse(value);
                            if (price == null || price < 0) return 'Preço deve ser maior ou igual a zero';
                            return null;
                          },
                        ),
                        if (_selectedStockItem != null && _selectedType == DocumentType.saida) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, size: 20, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Estoque disponível: ${_selectedStockItem!.quantity.toStringAsFixed(0)} unidades',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedStockItem != null &&
                              _quantityController.text.isNotEmpty &&
                              _priceController.text.isNotEmpty) {
                            final quantity = double.tryParse(_quantityController.text) ?? 0.0;
                            final price = double.tryParse(_priceController.text) ?? 0.0;
                            
                            if (quantity > 0 && price >= 0) {
                              _addItem();
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        child: const Text('Adicionar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _addItem() {
    if (_selectedStockItem == null) return;

    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (quantity <= 0 || price < 0) return;

    // Validação de estoque para documentos de saída
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
              'Disponível: ${_selectedStockItem!.quantity.toStringAsFixed(0)}\n'
              'Já selecionado: ${currentItemQuantity.toStringAsFixed(0)}\n'
              'Solicitado: ${quantity.toStringAsFixed(0)}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    // Check if item already exists
    final existingIndex = _items.indexWhere(
      (item) => item.stockItemId == _selectedStockItem!.id,
    );

    setState(() {
      if (existingIndex != -1) {
        // Update existing item
        final existingItem = _items[existingIndex];
        _items[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
          unitValue: price,
        );
      } else {
        // Add new item
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
      builder: (context) => AlertDialog(
        title: const Text('Remover Item'),
        content: Text('Deseja remover "${_items[index].stockItemName}" do documento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
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
    
    // Validar se cliente/fornecedor foi selecionado conforme o tipo
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

      final totalValue = _items.fold<double>(0.0, (sum, item) => sum + item.totalValue);      final document = DocumentModel(
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
        return 'Desconhecido'; // Mantém para compatibilidade, mas não será exibido
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
