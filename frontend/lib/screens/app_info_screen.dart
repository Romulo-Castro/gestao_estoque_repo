// lib/screens/app_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/error_handler.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  Map<String, String> _systemInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      setState(() {
        _systemInfo = {
          'App Name': 'Gestão de Estoque PRO',
          'Version': '1.0.0',
          'Build Number': '1',
          'Platform': Theme.of(context).platform.toString(),
          'Flutter Version': 'Latest Stable',
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Erro ao carregar informações do app');
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ErrorHandler.showSuccessSnackBar(context, 'Copiado para área de transferência');
  }

  Widget _buildInfoCard({
    required String title,
    required Map<String, String> data,
    IconData? icon,
  }) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${entry.key}:',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _copyToClipboard(entry.value),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Informações do App')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final authProvider = context.watch<AuthProvider>();
    final storeProvider = context.watch<StoreProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();

    final authInfo = {
      'Usuário': authProvider.user?.name ?? 'Não logado',
      'Email': authProvider.user?.email ?? 'N/A',
      'Token': authProvider.isAuthenticated ? 'Válido' : 'Inválido',
      'Status': authProvider.isAuthenticated ? 'Autenticado' : 'Não autenticado',
    };

    final storeInfo = {
      'Loja Selecionada': storeProvider.selectedStore?.name ?? 'Nenhuma',
      'Total de Lojas': storeProvider.stores.length.toString(),
      'Status da Loja': storeProvider.isLoading ? 'Carregando...' : 'Carregado',
      'Erro da Loja': storeProvider.error ?? 'Nenhum',
    };

    final statsInfo = {
      'Total Produtos': dashboardProvider.stats.totalProducts.toString(),
      'Total Documentos': dashboardProvider.stats.totalDocuments.toString(),
      'Total Clientes': dashboardProvider.stats.totalCustomers.toString(),
      'Total Fornecedores': dashboardProvider.stats.totalSuppliers.toString(),
      'Valor do Estoque': 'R\$ ${dashboardProvider.stats.totalStockValue.toStringAsFixed(2)}',
      'Status Stats': dashboardProvider.isLoading ? 'Carregando...' : 'Carregado',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informações do App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),            onPressed: () {
              setState(() => _isLoading = true);
              _loadAppInfo();
              dashboardProvider.fetchDashboardStats();
            },
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildInfoCard(
            title: 'Informações do Aplicativo',
            data: _systemInfo,
            icon: Icons.info,
          ),
          _buildInfoCard(
            title: 'Autenticação',
            data: authInfo,
            icon: Icons.person,
          ),
          _buildInfoCard(
            title: 'Loja Atual',
            data: storeInfo,
            icon: Icons.store,
          ),
          _buildInfoCard(
            title: 'Estatísticas do Dashboard',
            data: statsInfo,
            icon: Icons.dashboard,
          ),
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Ações de Debug',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [                      ElevatedButton.icon(
                        onPressed: () => dashboardProvider.fetchDashboardStats(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Recarregar Stats'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => storeProvider.fetchStores(),
                        icon: const Icon(Icons.store),
                        label: const Text('Recarregar Lojas'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final debugInfo = '''
App: ${_systemInfo['App Name']} v${_systemInfo['Version']}
Platform: ${_systemInfo['Platform']}
User: ${authInfo['Usuário']} (${authInfo['Email']})
Store: ${storeInfo['Loja Selecionada']}
Products: ${statsInfo['Total Produtos']}
Documents: ${statsInfo['Total Documentos']}
Customers: ${statsInfo['Total Clientes']}
Suppliers: ${statsInfo['Total Fornecedores']}
Stock Value: ${statsInfo['Valor do Estoque']}
                          ''';
                          _copyToClipboard(debugInfo);
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar Debug Info'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Card(
            margin: EdgeInsets.all(8.0),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sobre',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sistema de Gestão de Estoque desenvolvido com Flutter. '
                    'Este aplicativo oferece funcionalidades completas para '
                    'gerenciamento de estoque, documentos, clientes e fornecedores.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toque em qualquer valor para copiá-lo para a área de transferência.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
