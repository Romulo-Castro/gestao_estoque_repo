// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importar Providers
import 'core/presentation/providers/auth_provider.dart';
import 'core/presentation/providers/store_provider.dart';
import 'core/presentation/providers/dashboard_provider.dart';
import 'core/presentation/providers/layout_provider.dart';
import 'core/presentation/providers/item_group_provider.dart';
import 'core/presentation/providers/customer_provider.dart';
import 'core/presentation/providers/supplier_provider.dart';
import 'core/presentation/providers/document_provider.dart';
import 'core/presentation/providers/stock_provider.dart';

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
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),        ChangeNotifierProxyProvider<AuthProvider, StoreProvider>(
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
      child: MaterialApp(
        title: 'Gestão de Estoques PRO', // Nome que aparece no gerenciador de apps
        // Definição do Tema Visual
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo, // Cor base para gerar a paleta
              // brightness: Brightness.light, // Opcional: Forçar tema claro
              // primary: Colors.indigo[700], // Opcional: Ajustar cor primária
          ),
          useMaterial3: true, // Habilita o visual mais recente do Material Design
          visualDensity: VisualDensity.adaptivePlatformDensity, // Ajusta espaçamento para a plataforma
          // Tema para AppBar
          appBarTheme: AppBarTheme(
            elevation: 1.5, // Sombra um pouco mais pronunciada
            centerTitle: true,
            backgroundColor: Colors.indigo[600], // Um tom de índigo
            foregroundColor: Colors.white, // Cor para título e ícones
            titleTextStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500, // Semi-bold
                color: Colors.white,
                letterSpacing: 0.5), // Leve espaçamento
          ),
          // Tema para Campos de Texto
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[400]!), // Borda cinza claro
            ),
            enabledBorder: OutlineInputBorder( // Borda quando não focado
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder( // Borda quando focado
               borderRadius: BorderRadius.circular(8.0),
               borderSide: const BorderSide(color: Colors.indigo, width: 1.5), // Usa cor primária
            ),
            filled: true,
            fillColor: Colors.grey[100], // Fundo levemente acinzentado
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
            hintStyle: TextStyle(color: Colors.grey[500]) // Estilo para hintText
          ),
          // Tema para Botões Elevados
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.indigo, // Cor primária como fundo
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)), // Botões mais arredondados
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              elevation: 3.0, // Sombra do botão
            ),
          ),
          // Tema para Floating Action Button
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.deepOrangeAccent[400], // Cor de destaque
            foregroundColor: Colors.white,
            elevation: 4.0,
          ),
          // Tema para ChoiceChip (usado em WelcomeScreen)
          chipTheme: ChipThemeData(
             selectedColor: Colors.indigo.withAlpha(40), // Cor de seleção com transparência
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             labelStyle: TextStyle(color: Colors.grey[800]), // Cor do texto padrão
             secondaryLabelStyle: const TextStyle(color: Colors.indigo) // Cor do texto quando selecionado
          ),
           // Tema para ListTile (usado em Drawers e listas)
           listTileTheme: ListTileThemeData(
             selectedTileColor: Colors.indigo.withAlpha(25), // Cor de fundo quando selecionado
             iconColor: Colors.grey[600], // Cor padrão dos ícones
           ),
        ),
        debugShowCheckedModeBanner: false, // Remove a faixa "Debug"
        // Widget inicial da aplicação, controlado pelo AuthWrapper
        initialRoute: '/',
        // Definição das rotas nomeadas
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
