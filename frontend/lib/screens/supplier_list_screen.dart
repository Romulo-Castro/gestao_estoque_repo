// frontend/lib/screens/supplier_list_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "/models/supplier_model.dart";
import "/providers/supplier_provider.dart";
import "/providers/store_provider.dart";
import "/providers/layout_provider.dart";
import "/screens/edit_supplier_screen.dart";
import "/widgets/app_drawer.dart";
import "/utils/error_handler.dart";

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
      if (storeId != null) {
        Provider.of<SupplierProvider>(context, listen: false).setStoreId(storeId);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<StoreProvider>().selectedStoreId;
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);

    // Use post-frame callback to avoid setState during build
    if (storeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        supplierProvider.setStoreId(storeId);
      });
    }

    if (storeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Fornecedores")),
        drawer: const AppDrawer(),
        body: const Center(
          child: Text("Por favor, selecione uma loja primeiro."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fornecedores"),
        actions: [
          Consumer<LayoutProvider>(
            builder: (ctx, layoutProvider, _) => IconButton(
              icon: Icon(layoutProvider.supplierLayoutType.icon),
              tooltip: "Alterar layout: ${layoutProvider.supplierLayoutType.displayName}",
              onPressed: () => layoutProvider.toggleSupplierLayout(),
            ),
          ),
          Consumer<SupplierProvider>(
            builder: (ctx, provider, _) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : () => provider.fetchSuppliers(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<SupplierProvider>(
        builder: (ctx, supplierProvider, child) {
          if (supplierProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (supplierProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Erro: ${supplierProvider.error}"),
                  ElevatedButton(
                    onPressed: () => supplierProvider.fetchSuppliers(),
                    child: const Text("Tentar Novamente"),
                  ),
                ],
              ),
            );
          }

          if (supplierProvider.suppliers.isEmpty) {
            return const Center(
              child: Text("Nenhum fornecedor cadastrado."),
            );
          }

          return Consumer<LayoutProvider>(
            builder: (ctx, layoutProvider, _) => _buildLayoutBasedView(
              supplierProvider,
              layoutProvider.supplierLayoutType,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const EditSupplierScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLayoutBasedView(SupplierProvider supplierProvider, LayoutType layoutType) {
    switch (layoutType) {
      case LayoutType.list:
        return _buildListView(supplierProvider);
      case LayoutType.grid:
        return _buildGridView(supplierProvider);
      case LayoutType.card:
        return _buildCardView(supplierProvider);
    }
  }

  Widget _buildListView(SupplierProvider supplierProvider) {
    return ListView.builder(
      itemCount: supplierProvider.suppliers.length,
      itemBuilder: (ctx, index) {
        final supplier = supplierProvider.suppliers[index];
        return _buildSupplierListTile(supplier);
      },
    );
  }

  Widget _buildGridView(SupplierProvider supplierProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1.2,
      ),
      itemCount: supplierProvider.suppliers.length,
      itemBuilder: (ctx, index) {
        final supplier = supplierProvider.suppliers[index];
        return _buildSupplierGridCard(supplier);
      },
    );
  }

  Widget _buildCardView(SupplierProvider supplierProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: supplierProvider.suppliers.length,
      itemBuilder: (ctx, index) {
        final supplier = supplierProvider.suppliers[index];
        return _buildSupplierCard(supplier);
      },
    );
  }
  Widget _buildSupplierListTile(Supplier supplier) {
    return ListTile(
      leading: CircleAvatar(child: Text(supplier.name.isNotEmpty ? supplier.name.substring(0, 1) : "?")),
      title: Text(supplier.name),
      subtitle: Text(supplier.email ?? supplier.phone ?? "Sem contato"),
      trailing: _buildSupplierTrailingAction(supplier),
      onTap: () => _navigateToSupplierDetail(supplier),
    );
  }
  Widget _buildSupplierGridCard(Supplier supplier) {
    return Card(
      child: InkWell(
        onTap: () => _navigateToSupplierDetail(supplier),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                child: Text(supplier.name.isNotEmpty ? supplier.name.substring(0, 1) : "?"),
              ),
              const SizedBox(height: 8),
              Text(
                supplier.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                supplier.email ?? supplier.phone ?? "Sem contato",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildSupplierTrailingAction(supplier),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSupplierCard(Supplier supplier) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: InkWell(
        onTap: () => _navigateToSupplierDetail(supplier),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                child: Text(supplier.name.isNotEmpty ? supplier.name.substring(0, 1) : "?"),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (supplier.email != null)
                      Text(
                        "Email: ${supplier.email}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    if (supplier.phone != null)
                      Text(
                        "Telefone: ${supplier.phone}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    if (supplier.address != null)
                      Text(
                        "Endereço: ${supplier.address}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              _buildSupplierTrailingAction(supplier),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSupplierTrailingAction(Supplier supplier) {
    return IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () => _confirmDeleteSupplier(supplier),
    );
  }

  void _navigateToSupplierDetail(Supplier supplier) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => EditSupplierScreen(supplierId: supplier.id),
      ),
    );
  }
  Future<void> _confirmDeleteSupplier(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Exclusão"),
        content: Text("Tem certeza que deseja excluir o fornecedor ${supplier.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await Provider.of<SupplierProvider>(context, listen: false)
            .deleteSupplier(supplier.id);
        ErrorHandler.showSuccessSnackBar(context, "Fornecedor excluído!");
      } catch (e) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }
}
