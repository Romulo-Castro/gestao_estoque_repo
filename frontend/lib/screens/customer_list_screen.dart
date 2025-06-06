// frontend/lib/screens/customer_list_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "/models/customer_model.dart";
import "/providers/customer_provider.dart";
import "/providers/store_provider.dart";
import "/providers/layout_provider.dart";
import "/screens/edit_customer_screen.dart";
import "/widgets/app_drawer.dart";
import "/utils/error_handler.dart";

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

    // Use post-frame callback to avoid setState during build
    if (storeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        customerProvider.setStoreId(storeId);
      });
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
    }    return Scaffold(
      appBar: AppBar(
        title: const Text("Clientes"),
        actions: [
          // Botão de layout
          Consumer<LayoutProvider>(
            builder: (ctx, layoutProvider, _) => IconButton(
              icon: Icon(layoutProvider.customerLayoutType.icon),
              tooltip: "Alterar layout: ${layoutProvider.customerLayoutType.displayName}",
              onPressed: () => layoutProvider.toggleCustomerLayout(),
            ),
          ),
          // Botão para recarregar, se necessário
          Consumer<CustomerProvider>(
            builder: (ctx, provider, _) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : () => provider.fetchCustomers(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),      body: Consumer<CustomerProvider>(
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

          // Layout baseado na preferência do usuário
          return Consumer<LayoutProvider>(
            builder: (ctx, layoutProvider, _) => _buildLayoutBasedView(
              customerProvider,
              layoutProvider.customerLayoutType,
            ),
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

  // Layout-based view methods
  Widget _buildLayoutBasedView(CustomerProvider customerProvider, LayoutType layoutType) {
    switch (layoutType) {
      case LayoutType.list:
        return _buildListView(customerProvider);
      case LayoutType.grid:
        return _buildGridView(customerProvider);
      case LayoutType.card:
        return _buildCardView(customerProvider);
    }
  }

  Widget _buildListView(CustomerProvider customerProvider) {
    return ListView.builder(
      itemCount: customerProvider.customers.length,
      itemBuilder: (ctx, index) {
        final customer = customerProvider.customers[index];
        return _buildCustomerListTile(customer);
      },
    );
  }

  Widget _buildGridView(CustomerProvider customerProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1.2,
      ),
      itemCount: customerProvider.customers.length,
      itemBuilder: (ctx, index) {
        final customer = customerProvider.customers[index];
        return _buildCustomerGridCard(customer);
      },
    );
  }

  Widget _buildCardView(CustomerProvider customerProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: customerProvider.customers.length,
      itemBuilder: (ctx, index) {
        final customer = customerProvider.customers[index];
        return _buildCustomerCard(customer);
      },
    );
  }
  Widget _buildCustomerListTile(Customer customer) {
    return ListTile(
      leading: CircleAvatar(child: Text(customer.name.isNotEmpty ? customer.name.substring(0, 1) : "?")),
      title: Text(customer.name),
      subtitle: Text(customer.email ?? customer.phone ?? "Sem contato"),
      trailing: _buildCustomerTrailingAction(customer),
      onTap: () => _navigateToCustomerDetail(customer),
    );
  }  Widget _buildCustomerGridCard(Customer customer) {
    return Card(
      child: InkWell(
        onTap: () => _navigateToCustomerDetail(customer),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                child: Text(customer.name.isNotEmpty ? customer.name.substring(0, 1) : "?"),
              ),
              const SizedBox(height: 8),
              Text(
                customer.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                customer.email ?? customer.phone ?? "Sem contato",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildCustomerTrailingAction(customer),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: InkWell(
        onTap: () => _navigateToCustomerDetail(customer),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                child: Text(customer.name.isNotEmpty ? customer.name.substring(0, 1) : "?"),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (customer.email != null)
                      Text(
                        "Email: ${customer.email}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    if (customer.phone != null)
                      Text(
                        "Telefone: ${customer.phone}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    if (customer.address != null)
                      Text(
                        "Endereço: ${customer.address}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              _buildCustomerTrailingAction(customer),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildCustomerTrailingAction(Customer customer) {
    return IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () => _confirmDeleteCustomer(customer),
    );
  }

  void _navigateToCustomerDetail(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => EditCustomerScreen(customerId: customer.id),
      ),
    );
  }
  Future<void> _confirmDeleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Exclusão"),
        content: Text("Tem certeza que deseja excluir o cliente ${customer.name}?"),
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
    
    if (confirm == true) {      try {
        await Provider.of<CustomerProvider>(context, listen: false)
            .deleteCustomer(customer.id);
        ErrorHandler.showSuccessSnackBar(context, "Cliente excluído!");
      } catch (e) {
        ErrorHandler.showErrorSnackBar(context, "Erro ao excluir: $e");
      }
    }
  }
}
