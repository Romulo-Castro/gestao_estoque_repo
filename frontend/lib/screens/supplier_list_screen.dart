// frontend/lib/screens/supplier_list_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "/providers/supplier_provider.dart";
import "/providers/store_provider.dart";
import "/screens/edit_supplier_screen.dart";
import "/widgets/app_drawer.dart";

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();
    // Acessar o provider após o build inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
      if (storeId != null) {
        Provider.of<SupplierProvider>(context, listen: false).setStoreId(storeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Observar o ID da loja selecionada
    final storeId = context.watch<StoreProvider>().selectedStoreId;
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);

    // Se a loja mudar, atualizar o provider
    if (storeId != null) {
      supplierProvider.setStoreId(storeId);
    }

    // Se não houver loja selecionada, mostra uma mensagem
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

          // Lista de fornecedores
          return ListView.builder(
            itemCount: supplierProvider.suppliers.length,
            itemBuilder: (ctx, index) {
              final supplier = supplierProvider.suppliers[index];
              return ListTile(
                leading: CircleAvatar(child: Text(supplier.name.substring(0, 1))),
                title: Text(supplier.name),
                subtitle: Text(supplier.email ?? supplier.phone ?? "Sem contato"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Confirmar Exclusão"),
                        content: Text("Tem certeza que deseja excluir o fornecedor ${supplier.name}?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancelar")),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await supplierProvider.deleteSupplier(supplier.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Fornecedor excluído!"), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erro ao excluir: $e"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => EditSupplierScreen(supplierId: supplier.id), // Passa o ID para edição
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const EditSupplierScreen(), // Sem ID para adição
            ),
          );
        },
      ),
    );
  }
}
