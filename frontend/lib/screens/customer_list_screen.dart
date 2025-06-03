// frontend/lib/screens/customer_list_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "/providers/customer_provider.dart";
import "/providers/store_provider.dart";
import "/screens/edit_customer_screen.dart";
import "/widgets/app_drawer.dart";

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    // Acessar o provider após o build inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
      if (storeId != null) {
        Provider.of<CustomerProvider>(context, listen: false).setStoreId(storeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Observar o ID da loja selecionada
    final storeId = context.watch<StoreProvider>().selectedStoreId;
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);

    // Se a loja mudar, atualizar o provider
    if (storeId != null) {
      customerProvider.setStoreId(storeId);
    }

    // Se não houver loja selecionada, mostra uma mensagem
    if (storeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Clientes")),
        drawer: const AppDrawer(),
        body: const Center(
          child: Text("Por favor, selecione uma loja primeiro."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Clientes"),
        actions: [
          // Botão para recarregar, se necessário
          Consumer<CustomerProvider>(
            builder: (ctx, provider, _) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : () => provider.fetchCustomers(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<CustomerProvider>(
        builder: (ctx, customerProvider, child) {
          if (customerProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (customerProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Erro: ${customerProvider.error}"),
                  ElevatedButton(
                    onPressed: () => customerProvider.fetchCustomers(),
                    child: const Text("Tentar Novamente"),
                  ),
                ],
              ),
            );
          }

          if (customerProvider.customers.isEmpty) {
            return const Center(
              child: Text("Nenhum cliente cadastrado."),
            );
          }

          // Lista de clientes
          return ListView.builder(
            itemCount: customerProvider.customers.length,
            itemBuilder: (ctx, index) {
              final customer = customerProvider.customers[index];
              return ListTile(
                leading: CircleAvatar(child: Text(customer.name.substring(0, 1))),
                title: Text(customer.name),
                subtitle: Text(customer.email ?? customer.phone ?? "Sem contato"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    // Confirmação antes de deletar
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Confirmar Exclusão"),
                        content: Text("Tem certeza que deseja excluir o cliente ${customer.name}?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancelar")),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await customerProvider.deleteCustomer(customer.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Cliente excluído!"), backgroundColor: Colors.green),
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
                      builder: (ctx) => EditCustomerScreen(customerId: customer.id), // Passa o ID para edição
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
              builder: (ctx) => const EditCustomerScreen(), // Sem ID para adição
            ),
          );
        },
      ),
    );
  }
}
