// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart'; // Para AppRoutes
import '../providers/store_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/app_drawer.dart'; // Importar o Drawer
import '../widgets/barcode_scanner_page.dart'; // Importar o scanner
import '../../../shared/utils/error_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch stores after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      // Only fetch if we haven't fetched yet and no error exists
      if (!storeProvider.isLoading && storeProvider.error == null && storeProvider.stores.isEmpty) {
        debugPrint("HomeScreen: Iniciando busca de lojas após autenticação validada");
        storeProvider.fetchStores();
      }
    });
  }

  // Helper para mostrar snackbar de funcionalidades não implementadas
  void _showTodoSnackbar(BuildContext context, String featureName) {
    ErrorHandler.showErrorSnackBar(context, "$featureName ainda não implementado.");
  }

  // Helper para criar uma nova loja
  void _navigateToCreateStore(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.storeManagement, arguments: null);
  }

  // Helper methods for minimalist cards
  Widget _buildPrimaryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    Color? iconColor,
    int? count,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48.0,
                color: iconColor ?? colorScheme.primary,
              ),
              const SizedBox(height: 12.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (count != null) ...[
                const SizedBox(height: 8.0),
                isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor ?? colorScheme.primary,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: (iconColor ?? colorScheme.primary).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          count.toString(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: iconColor ?? colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32.0,
                color: iconColor ?? colorScheme.primary,
              ),
              const SizedBox(height: 8.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    Color? iconColor,
    int? count,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28.0,
                color: iconColor ?? colorScheme.primary,
              ),
              const SizedBox(height: 4.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (count != null) ...[
                const SizedBox(height: 2.0),
                isLoading
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: iconColor ?? colorScheme.primary,
                        ),
                      )
                    : Text(
                        count.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: iconColor ?? colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper para o conteúdo principal da tela
  Widget _buildBody(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();

    if (storeProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (storeProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Erro ao carregar lojas: ${storeProvider.error}", textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => storeProvider.fetchStores(), child: const Text("Tentar Novamente")),
          ],
        ),
      );
    }

    if (storeProvider.hasNoStores) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Nenhuma loja encontrada.", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text("Crie sua primeira loja para começar.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_business_outlined),
              label: const Text("Criar Nova Loja"),
              onPressed: () => _navigateToCreateStore(context),
            ),
          ],
        ),
      );
    }

    // Atualizar dashboard quando loja mudar
    if (storeProvider.selectedStore != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only update if the store ID has actually changed
        if (dashboardProvider.storeId != storeProvider.selectedStore!.id) {
          dashboardProvider.setStoreId(storeProvider.selectedStore!.id);
        }
      });
    }

    // Se chegou aqui, tem lojas e não está carregando nem com erro
    final selectedStoreName = storeProvider.selectedStore?.name ?? "Todas as Lojas";

    // nenhuma seleção específica = todas as lojas

    return Column(
      children: [
        // --- Seletor de Loja Visível ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          width: double.infinity,
          color: Colors.grey[200], // Ou cor do tema
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  "Loja: $selectedStoreName",
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Selecionar Loja"),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: storeProvider.stores.length + 1,
                          itemBuilder: (ctx, index) {
                            if (index == 0) {
                              final isAll = storeProvider.selectedStore == null;
                              return ListTile(
                                title: const Text('Todas as Lojas'),
                                leading: isAll
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : const Icon(Icons.storefront_outlined),
                                onTap: () {
                                  storeProvider.selectAllStores();
                                  Navigator.of(ctx).pop();
                                },
                              );
                            }
                            final store = storeProvider.stores[index - 1];
                            final isSelected = store.id == storeProvider.selectedStoreId;
                            return ListTile(
                              title: Text(store.name),
                              subtitle: store.address != null && store.address!.isNotEmpty
                                  ? Text(store.address!)
                                  : null,
                              selected: isSelected,
                              leading: isSelected
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : const Icon(Icons.store_outlined),
                              onTap: () {
                                storeProvider.selectStore(store);
                                Navigator.of(ctx).pop();
                              },
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text("Cancelar"),
                        ),
                        TextButton(
                          onPressed: () => _navigateToCreateStore(context),
                          child: const Text("Nova Loja"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // --- Grid de Cards ---
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Primary Actions Row
                Row(
                  children: [
                    Expanded(
                      child: _buildPrimaryCard(
                        context,
                        title: "Mercadorias",
                        icon: Icons.inventory_2_outlined,
                        count: dashboardProvider.stats.totalProducts,
                        isLoading: dashboardProvider.isLoading,
                        onTap: () {
                          if (storeProvider.stores.isEmpty) {
                            ErrorHandler.showErrorSnackBar(context, "Nenhuma loja cadastrada.");
                            return;
                          }
                          Navigator.pushNamed(context, AppRoutes.stockList);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPrimaryCard(
                        context,
                        title: "Documentos",
                        icon: Icons.receipt_long_outlined,
                        iconColor: Colors.orange[700],
                        count: dashboardProvider.stats.totalDocuments,
                        isLoading: dashboardProvider.isLoading,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.documentList),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Quick Actions Row
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: "Nova Entrada",
                        icon: Icons.add_shopping_cart_outlined,
                        iconColor: Colors.green[700],
                        onTap: () => Navigator.pushNamed(
                          context, 
                          AppRoutes.editDocument, 
                          arguments: {'type': 'ENTRADA'}
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: "Nova Saída",
                        icon: Icons.remove_shopping_cart_outlined,
                        iconColor: Colors.redAccent[700],
                        onTap: () => Navigator.pushNamed(
                          context, 
                          AppRoutes.editDocument, 
                          arguments: {'type': 'SAIDA'}
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: "Ler Código",
                        icon: Icons.qr_code_scanner_outlined,
                        iconColor: Colors.purple[700],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BarcodeScannerPage(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Secondary Features Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 12.0,
                    childAspectRatio: 1.2,
                    children: [
                      _buildSecondaryCard(
                        context,
                        title: "Relatórios",
                        icon: Icons.assessment_outlined,
                        iconColor: Colors.blue[700],
                        onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
                      ),
                      _buildSecondaryCard(
                        context,
                        title: "Clientes",
                        icon: Icons.people_alt_outlined,
                        iconColor: Colors.lightBlue[700],
                        count: dashboardProvider.stats.totalCustomers,
                        isLoading: dashboardProvider.isLoading,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.customerList),
                      ),
                      _buildSecondaryCard(
                        context,
                        title: "Fornecedores",
                        icon: Icons.groups_outlined,
                        iconColor: Colors.brown[700],
                        count: dashboardProvider.stats.totalSuppliers,
                        isLoading: dashboardProvider.isLoading,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.supplierList),
                      ),
                      _buildSecondaryCard(
                        context,
                        title: "Grupos",
                        icon: Icons.category_outlined,
                        iconColor: Colors.amber[700],
                        count: dashboardProvider.stats.totalGroups,
                        isLoading: dashboardProvider.isLoading,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.itemGroupList),
                      ),
                      _buildSecondaryCard(
                        context,
                        title: "Importar",
                        icon: Icons.file_upload_outlined,
                        iconColor: Colors.indigo[700],
                        onTap: () {
                          if (storeProvider.selectedStoreId == null) {
                            ErrorHandler.showErrorSnackBar(context, "Selecione uma loja primeiro.");
                            return;
                          }
                          Navigator.pushNamed(context, AppRoutes.bulkImport);
                        },
                      ),
                      _buildSecondaryCard(
                        context,
                        title: "Configurações",
                        icon: Icons.settings_outlined,
                        iconColor: Colors.grey[700],
                        onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Stock e Inventário"),
        actions: [
          IconButton(onPressed: () => _showTodoSnackbar(context, "Busca Rápida"), icon: const Icon(Icons.search), tooltip: "Busca Rápida"),
        ],
      ),
      body: _buildBody(context), // Chama o helper para construir o corpo
    );
  }
}
