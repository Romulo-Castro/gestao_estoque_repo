// lib/core/presentation/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../../../shared/utils/error_handler.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  // Helper para mostrar snackbar de funcionalidades não implementadas
  void _showTodoSnackbar(BuildContext context, String featureName) {
    ErrorHandler.showErrorSnackBar(context, "$featureName ainda não implementado.");
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final storeProvider = Provider.of<StoreProvider>(context);
    final userName = authProvider.user?.name ?? 'Usuário';
    final userEmail = authProvider.user?.email ?? '';
    final selectedStoreName = storeProvider.selectedStore?.name ?? 'Nenhuma loja selecionada';

    return Drawer(
      width: 280, // Set a fixed width for consistency
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

          // Itens do Menu - Wrapped in Expanded to prevent overflow
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
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
                ErrorHandler.showErrorSnackBar(context, "Selecione uma loja primeiro.");
                return;
              }
              Navigator.pushNamed(context, AppRoutes.stockList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Importar Mercadorias'),
            onTap: () {
              Navigator.pop(context);
              if (storeProvider.selectedStoreId == null) {
                ErrorHandler.showErrorSnackBar(context, "Selecione uma loja primeiro.");
                return;
              }
              Navigator.pushNamed(context, AppRoutes.bulkImport);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Documentos'),
            onTap: () {
              Navigator.pop(context);
              if (storeProvider.selectedStoreId == null) {
                ErrorHandler.showErrorSnackBar(context, "Selecione uma loja primeiro.");
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
              Navigator.pushNamed(context, AppRoutes.expenses);
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
                ErrorHandler.showErrorSnackBar(context, "Selecione uma loja primeiro.");
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
                ErrorHandler.showErrorSnackBar(context, "Selecione uma loja primeiro.");
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
                ErrorHandler.showErrorSnackBar(context, "Selecione uma loja primeiro.");
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
              Navigator.pushNamed(context, AppRoutes.help);
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
          // Use SizedBox instead of Spacer in ListView
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () async {
              // Perform logout
              await authProvider.logout();
              
              // Check if the widget is still mounted before popping
              if (context.mounted) {
                Navigator.of(context).pop(); // Close the drawer
              }

              // Defer navigation to after drawer close and ensure context is valid
              // for the navigation call itself.
              // No need for another mounted check here as addPostFrameCallback
              // defers the execution, and the navigator uses a new context.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // It's generally safer to use the context from the builder of MaterialApp 
                // or a context that is known to be alive for global navigations.
                // However, for this pattern, the context passed to pushNamedAndRemoveUntil
                // should ideally be one that's still valid.
                // If issues persist, consider obtaining a global navigator key's context.
                Navigator.pushNamedAndRemoveUntil(
                  context, // This context might be an issue if AppDrawer is disposed quickly.
                           // A more robust solution might involve a global navigator key.
                  AppRoutes.login,
                  (route) => false,
                );
              });
            },
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
