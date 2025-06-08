// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importar Providers
import 'core/presentation/providers/auth_provider.dart';
import 'core/presentation/providers/user_profile_provider.dart';
import 'core/presentation/providers/store_provider.dart';
import 'core/presentation/providers/dashboard_provider.dart';
import 'core/presentation/providers/layout_provider.dart';
import 'core/presentation/providers/item_group_provider.dart';
import 'core/presentation/providers/customer_provider.dart';
import 'core/presentation/providers/supplier_provider.dart';
import 'core/presentation/providers/document_provider.dart';
import 'core/presentation/providers/stock_provider.dart';
import 'core/presentation/providers/theme_provider.dart';

// Importar Telas
import 'core/presentation/screens/login_screen.dart';
import 'core/presentation/screens/register_screen.dart';
import 'core/presentation/screens/stock_screen.dart';
import 'core/presentation/screens/welcome_screen.dart';
import 'core/presentation/screens/store_management_screen.dart';
import 'core/presentation/screens/home_screen.dart';
import 'core/presentation/screens/item_group_list_screen.dart';
import 'core/presentation/screens/edit_item_group_screen.dart';
import 'core/presentation/screens/customer_list_screen.dart';
import 'core/presentation/screens/edit_customer_screen.dart';
import 'core/presentation/screens/supplier_list_screen.dart';
import 'core/presentation/screens/edit_supplier_screen.dart';
import 'core/presentation/screens/document_list_screen.dart';
import 'core/presentation/screens/edit_document_screen.dart';
import 'core/presentation/screens/document_detail_screen.dart';
import 'core/presentation/screens/reports_screen.dart';
import 'core/presentation/screens/settings_screen.dart';
import 'core/presentation/screens/app_info_screen.dart';
import 'core/presentation/screens/bulk_import_screen.dart';
import 'core/presentation/screens/expenses_screen.dart';
import 'core/presentation/screens/help_screen.dart';

// Importar Utilitários e Preferências
import 'shared/utils/app_prefs.dart';
import 'core/data/datasources/api_service.dart';
import 'shared/services/notification_service.dart';

// Clean Architecture
import 'shared/dependency_injection.dart';

// --- Constantes de Rotas Nomeadas ---
// Centraliza os nomes das rotas para evitar erros de digitação
class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const welcome = '/welcome';
  // 'home' agora aponta para o Dashboard principal
  static const home = '/home';
  // Rota específica para a tela que lista os itens de estoque
  static const stockList = '/stock-list';
  static const storeManagement = '/store-management';
  // Rotas para grupos de itens
  static const itemGroupList = '/item-group-list';
  static const editItemGroup = '/edit-item-group';
  // Rotas para clientes
  static const customerList = '/customer-list';
  static const editCustomer = '/edit-customer';
  // Rotas para fornecedores
  static const supplierList = '/supplier-list';
  static const editSupplier = '/edit-supplier';
  // Rotas para documentos
  static const documentList = '/document-list';
  static const editDocument = '/edit-document';
  static const documentDetail = '/document-detail';
  // Novas rotas
  static const reports = '/reports';
  static const settings = '/settings';
  static const appInfo = '/app-info'; // Nova rota para informações do app
  static const bulkImport = '/bulk-import'; // Nova rota para importação de mercadorias
  static const expenses = '/expenses'; // Nova rota para despesas
  static const help = '/help'; // Nova rota para ajuda
}

// --- Ponto de Entrada Principal ---
void main() async {
  // Necessário para garantir que plugins (como SharedPreferences) sejam inicializados
  // antes de `runApp` se você usar `await` antes dele (como fizemos em AppPrefs).
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o serviço de notificações locais (apenas em plataformas móveis)
  try {
    await NotificationService.initialize();
  } catch (e) {
    // Ignora erros de inicialização em plataformas não suportadas (como web)
    print('Notification service initialization failed (likely web platform): $e');
  }

  // Initialize Clean Architecture dependencies
  await initializeDependencies();

  // Roda o widget raiz da aplicação
  runApp(const MyApp());
}

// --- Widget Raiz da Aplicação ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Disponibiliza os providers para toda a árvore de widgets abaixo dele
    final apiService = ApiService(); // Instancia ApiService uma vez.

    return MultiProvider(
      providers: [
        // Provider para Autenticação
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        
        // User Profile Provider depends on Auth Provider
        ChangeNotifierProxyProvider<AuthProvider, UserProfileProvider>(
          create: (_) => UserProfileProvider(apiService, AuthProvider(apiService)),
          update: (context, auth, previous) {
            return UserProfileProvider(apiService, auth);
          },
        ),
        
        ChangeNotifierProxyProvider<AuthProvider, StoreProvider>(
          create: (_) => StoreProvider(),
          update: (context, auth, previous) {
            final provider = previous ?? StoreProvider();
            provider.updateAuthToken(auth.token);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (context, auth, previous) {
            final provider = previous ?? DashboardProvider();
            provider.updateAuthToken(auth.token);
            return provider;
          },        ),
        // Layout Provider - não precisa de ProxyProvider pois não depende de autenticação
        ChangeNotifierProvider(create: (_) => LayoutProvider()),
        // Theme Provider - não precisa de ProxyProvider pois não depende de autenticação
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ItemGroupProvider>(
          create: (_) => ItemGroupProvider(),
          update: (context, auth, previous) {
            final provider = previous ?? ItemGroupProvider();
            provider.updateAuthToken(auth.token);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, CustomerProvider>(
          create: (_) => CustomerProvider(),
          update: (context, auth, previous) {
            final provider = previous ?? CustomerProvider();
            provider.updateAuthToken(auth.token);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, SupplierProvider>(
          create: (_) => SupplierProvider(),
          update: (context, auth, previous) {
            final provider = previous ?? SupplierProvider();
            provider.updateAuthToken(auth.token);
            return provider;
          },
        ),        ChangeNotifierProxyProvider<AuthProvider, DocumentProvider>(
          create: (_) => DocumentProvider(),
          update: (context, auth, previous) {
            final provider = previous ?? DocumentProvider();
            provider.updateAuthToken(auth.token);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, StockProvider>(
          create: (_) => StockProvider(),
          update: (context, auth, previous) {
            final provider = previous ?? StockProvider();
            provider.updateAuthToken(auth.token);
            return provider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Gestão de Estoques PRO',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
          '/': (context) => const AuthWrapper(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.welcome: (context) => const WelcomeScreen(),
          // Dashboard route
          AppRoutes.home: (context) => const HomeScreen(),
          // Rota específica para a lista de estoque
          AppRoutes.stockList: (context) => const StockScreen(),
          AppRoutes.storeManagement: (context) => const StoreManagementScreen(),
          // Rotas para grupos de itens
          AppRoutes.itemGroupList: (context) => const ItemGroupListScreen(),
          AppRoutes.editItemGroup: (context) => const EditItemGroupScreen(),
          // Rotas para clientes
          AppRoutes.customerList: (context) => const CustomerListScreen(),
          AppRoutes.editCustomer: (context) => const EditCustomerScreen(),
          // Rotas para fornecedores
          AppRoutes.supplierList: (context) => const SupplierListScreen(),
          AppRoutes.editSupplier: (context) => const EditSupplierScreen(),
          // Rotas para documentos
          AppRoutes.documentList: (context) => const DocumentListScreen(),
          AppRoutes.editDocument: (context) => const EditDocumentScreen(),
          AppRoutes.documentDetail: (context) => const DocumentDetailScreen(documentId: 0), // Corrigido para passar o parâmetro obrigatório
          // Novas rotas
          AppRoutes.reports: (context) => const ReportsScreen(),
          AppRoutes.settings: (context) => const SettingsScreen(),
          AppRoutes.appInfo: (context) => const AppInfoScreen(), // Rota para informações do app
          AppRoutes.bulkImport: (context) => const BulkImportScreen(), // Rota para importação de mercadorias
          AppRoutes.expenses: (context) => const ExpensesScreen(), // Rota para despesas
          AppRoutes.help: (context) => const HelpScreen(), // Rota para ajuda
        },
      );
        },
      ),
    );
  }
}

// --- Widgets de Controle de Fluxo ---

// Decide entre Login ou (Welcome/Home Dashboard) baseado na autenticação
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.initializeAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Assiste (watch) o AuthProvider para reagir a mudanças no estado de autenticação
    final authProvider = Provider.of<AuthProvider>(context);

    // Mostra loading enquanto o provider verifica o estado inicial (_tryAutoLogin)
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Verificando sessão...")
          ],
        )),
      );
    }

    // Se o usuário está autenticado
    if (authProvider.isAuthenticated) {
      // Verifica se é o primeiro acesso (já passou pela tela de Welcome?)
      return FutureBuilder<bool>(
        future: AppPrefs.isFirstLaunch(),
        builder: (context, snapshot) {
          // Mostra loading enquanto verifica a preferência
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // Mostra erro se falhar ao ler a preferência
          if (snapshot.hasError) {
            return Scaffold(body: Center(child: Text('Erro ao verificar preferências: ${snapshot.error}')));
          }
          // Obtém o resultado (true se for o primeiro acesso)
          final bool isFirstTime = snapshot.data ?? true; // Assume true se houver erro
          // Se for o primeiro acesso, vai para a tela de Welcome/Configuração Inicial
          // Senão, vai para a tela principal (Home Dashboard)
          return isFirstTime ? const WelcomeScreen() : const HomeScreen();
        },
      );
    }
    // Se não está autenticado, mostra a tela de Login
    else {
      return const LoginScreen();
    }
  }
}
