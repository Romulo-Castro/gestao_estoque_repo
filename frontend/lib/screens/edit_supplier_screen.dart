// frontend/lib/screens/edit_supplier_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "/models/supplier_model.dart";
import "/providers/supplier_provider.dart";
import "/providers/store_provider.dart"; // Para obter o storeId
import "/utils/error_handler.dart";

class EditSupplierScreen extends StatefulWidget {
  final int? supplierId; // Null para adicionar, preenchido para editar

  const EditSupplierScreen({super.key, this.supplierId});

  @override
  State<EditSupplierScreen> createState() => _EditSupplierScreenState();
}

class _EditSupplierScreenState extends State<EditSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isInit = true;
  Supplier? _initialSupplierData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      if (widget.supplierId != null) {
        _loadSupplierData();
      }
      _isInit = false;
    }
  }

  Future<void> _loadSupplierData() async {
    setState(() {
      _isLoading = true;
    });    final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
    if (storeId == null) {
       ErrorHandler.showErrorSnackBar(context, "Erro: Loja não selecionada.");
       setState(() { _isLoading = false; });
       Navigator.of(context).pop(); // Volta se não tem loja
       return;
    }

    try {
      final provider = Provider.of<SupplierProvider>(context, listen: false);
      _initialSupplierData = provider.suppliers.firstWhere((s) => s.id == widget.supplierId);

      _nameController.text = _initialSupplierData!.name;
      _emailController.text = _initialSupplierData!.email ?? "";
      _phoneController.text = _initialSupplierData!.phone ?? "";
      _addressController.text = _initialSupplierData!.address ?? "";
      _notesController.text = _initialSupplierData!.notes ?? "";
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, "Erro ao carregar fornecedor: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);

    try {
      if (widget.supplierId == null) {
        // Criar novo fornecedor
        final supplier = Supplier(
          id: 0,
          storeId: Provider.of<StoreProvider>(context, listen: false).selectedStoreId!,
          name: _nameController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          createdAt: "",
          updatedAt: "",
        );        await supplierProvider.createSupplier(supplier);
        ErrorHandler.showSuccessSnackBar(context, "Fornecedor criado com sucesso!");
      } else {
        // Atualizar fornecedor existente
        final supplier = Supplier(
          id: widget.supplierId!,
          storeId: Provider.of<StoreProvider>(context, listen: false).selectedStoreId!,
          name: _nameController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          createdAt: _initialSupplierData!.createdAt,
          updatedAt: _initialSupplierData!.updatedAt,
        );
        await supplierProvider.updateSupplier(widget.supplierId!, supplier);
        ErrorHandler.showSuccessSnackBar(context, "Fornecedor atualizado com sucesso!");
      }
      Navigator.of(context).pop();
    } catch (error) {
      ErrorHandler.showErrorSnackBar(context, "Erro ao salvar fornecedor: $error");
    } finally {
      if (mounted) {
         setState(() {
           _isLoading = false;
         });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplierId == null ? "Adicionar Fornecedor" : "Editar Fornecedor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Nome*"),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Nome é obrigatório.";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: "Email"),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: "Telefone"),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: "Endereço"),
                      keyboardType: TextInputType.streetAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: "Observações"),
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Salvar Fornecedor"),
                        onPressed: _saveForm,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
