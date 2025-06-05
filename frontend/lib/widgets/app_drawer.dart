// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Para AppRoutes
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Helper para mostrar snackbar de TODO
  void _showTodoSnackbar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$featureName ainda não implementado."), duration: const Duration(seconds: 2))
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final storeProvider = Provider.of<StoreProvider>(context);
    final userName = authProvider.user?.name ?? 'Usuário';
    final userEmail = authProvider.user?.email ?? '';
    final selectedStoreName = storeProvider.selectedStore?.name ?? 'Nenhuma loja selecionada';

    return Drawer(
      child: Column(
        children: [
          // Cabeçalho do Drawer
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 24.0, color: Colors.indigo),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.indigo[700],
            ),
            otherAccountsPictures: [
              // Indicador de loja selecionada
              Tooltip(
                message: selectedStoreName,
                child: const CircleAvatar(
                  backgroundColor: Colors.white70,
                  child: Icon(Icons.store, color: Colors.indigo),
                ),
              ),
            ],
          ),

          // Itens do Menu
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Início'),
            onTap: () {
              Navigator.pop(context); // Fecha o drawer
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Estoque'),
            onTap: () {
              Navigator.pop(context);
              if (storeProvider.selectedStoreId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Selecione uma loja primeiro."))
                );
                return;
              }
              Navigator.pushNamed(context, AppRoutes.stockList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Documentos'),
            onTap: () {
              Navigator.pop(context);
              if (storeProvider.selectedStoreId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Selecione uma loja primeiro."))
                );
                return;
              }
              Navigator.pushNamed(context, AppRoutes.documentList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.wallet_outlined),
            title: const Text('Despesas'),
            onTap: () {
              Navigator.pop(context);
              _showTodoSnackbar(context, 'Despesas');
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment_outlined),
            title: const Text('Relatórios'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.reports);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Grupos de Itens'),
            onTap: () {
              Navigator.pop(context);
              if (storeProvider.selectedStoreId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Selecione uma loja primeiro."))
                );
                return;
              }
              Navigator.pushNamed(context, AppRoutes.itemGroupList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Fornecedores'),
            onTap: () {
              Navigator.pop(context);
              if (storeProvider.selectedStoreId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Selecione uma loja primeiro."))
                );
                return;
              }
              Navigator.pushNamed(context, AppRoutes.supplierList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('Clientes'),
            onTap: () {
              Navigator.pop(context);
              if (storeProvider.selectedStoreId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Selecione uma loja primeiro."))
                );
                return;
              }
              Navigator.pushNamed(context, AppRoutes.customerList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ajuda'),
            onTap: () {
              Navigator.pop(context);
              _showTodoSnackbar(context, 'Ajuda');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.store_outlined),
            title: const Text('Gerenciar Lojas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.storeManagement);
            },
          ),
          const Spacer(), // Empurra o item de logout para o final
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () async {
              // Perform logout then close drawer
              await authProvider.logout();
              Navigator.of(context).pop();
              // Defer navigation to after drawer close
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              });
            },
          ),
        ],
      ),
    );
  }
}
