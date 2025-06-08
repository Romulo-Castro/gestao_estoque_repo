// lib/screens/stock_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/stock_item.dart';
import '../../data/models/store_model.dart';
import '../providers/store_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/layout_provider.dart';
import '../../data/datasources/api_service.dart';
import '../screens/edit_stock_item_screen.dart';
import '../screens/bulk_import_screen.dart';
import '../../../shared/utils/app_prefs.dart';
import '../../../main.dart'; // Para AppRoutes
import '../../../shared/utils/error_handler.dart';
import '../widgets/app_drawer.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<StockItem> _stockItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _useCardLayout = false;
  int? _currentStoreId;
  int _quantityDecimals = 0;

  final ApiService _apiService = ApiService();
  StoreProvider? _storeProviderRef; // Referência para usar no dispose

  @override
  void initState() {
    super.initState();
    // Carrega preferências primeiro de forma síncrona (ou com await se necessário)
    // mas o carregamento inicial dos dados é feito depois que o provider estiver pronto
    _loadPreferencesAndInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obter a referência ao provider e adicionar listener AQUI
    // É mais seguro que no initState
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    // Removes old listener if exists
    _storeProviderRef?.removeListener(_storeChangeListener);
    _storeProviderRef = storeProvider;
    _storeProviderRef?.addListener(_storeChangeListener);

    // Verifica se a loja mudou desde a última vez (ex: ao voltar para esta tela)
    // e se os dados ainda não foram carregados para a loja atual
    if (_currentStoreId != storeProvider.selectedStoreId) {
        _storeChangeListener(); // Força a atualização se a loja mudou enquanto fora da tela
    }
  }

  @override
  void dispose() {
    // Remove o listener usando a referência guardada
    _storeProviderRef?.removeListener(_storeChangeListener);
    super.dispose();
  }

  // Carrega preferências e dados iniciais (chamado pelo initState)
  Future<void> _loadPreferencesAndInitialData() async {
    await _loadLayoutPreference();
    await _loadQuantityDecimalPreference();

    // Não busca dados aqui, espera didChangeDependencies e/ou _storeChangeListener
    // Apenas atualiza o estado de loading inicial se necessário
     if (mounted) {
         // Pega a loja atual do provider (listen: false)
         final initialStoreId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
         _currentStoreId = initialStoreId; // Define o ID inicial
         if (_currentStoreId == null) {
             setState(() => _isLoading = false); // Para loading se não há loja
         } else {
             // Tenta carregar os itens da loja inicial
             _loadStockItems(storeId: _currentStoreId!, showLoading: true);
         }
     }
  }

  // Listener chamado QUANDO A LOJA MUDA NO PROVIDER
  void _storeChangeListener() {
    // Usa listen: false pois estamos apenas reagindo à notificação
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final newStoreId = storeProvider.selectedStoreId;

    debugPrint("[StockScreen] _storeChangeListener chamado. newStoreId: $newStoreId, _currentStoreId: $_currentStoreId");

    // Verifica se a loja realmente mudou
    if (newStoreId != _currentStoreId) {
      // ★★★ VERIFICAÇÃO mounted ★★★
      if (!mounted) {
         debugPrint("[StockScreen] _storeChangeListener: Widget desmontado, saindo.");
         return;
      }

      debugPrint("[StockScreen] Listener: Loja alterada para ID: $newStoreId.");
      _currentStoreId = newStoreId; // Atualiza o ID local

      if (_currentStoreId != null) {
        // Limpa lista antiga, mostra loading e busca novos itens
        setState(() { _stockItems = []; _isLoading = true; _errorMessage = null; });
        _loadStockItems(storeId: _currentStoreId!); // Dispara o carregamento
      } else {
        // Nenhuma loja selecionada, limpa tudo
        setState(() { _stockItems = []; _isLoading = false; _errorMessage = null; });
      }
    }
  }

  // Carrega preferência de layout
  Future<void> _loadLayoutPreference() async {
    final useCards = await AppPrefs.getUseCardLayout();
    // ★★★ VERIFICAÇÃO mounted ★★★
    if (mounted) {
      setState(() => _useCardLayout = useCards);
    }
  }

   // Carrega preferência de decimais
   Future<void> _loadQuantityDecimalPreference() async {
      final decimals = await AppPrefs.getQuantityDecimals();
      // ★★★ VERIFICAÇÃO mounted ★★★
      if (mounted) {
          setState(() => _quantityDecimals = decimals);
      }
   }

  // Carrega os itens de estoque da API
  Future<void> _loadStockItems({required int storeId, bool showLoading = true}) async {
    // ★★★ VERIFICAÇÃO mounted ANTES DE QUALQUER COISA ASYNC ★★★
    if (!mounted) return;
    if (!_ensureApiServiceToken()) {
        if (mounted) setState(() => _isLoading = false); // Para loading se não autenticado
        return;
    }

    // Define loading APENAS se montado
    if (showLoading || _errorMessage != null) {
      setState(() { _isLoading = true; _errorMessage = null; });
    }

    try {
      debugPrint("[StockScreen] Buscando itens para loja $storeId...");
      final items = await _apiService.fetchStockItems(storeId); // await
      // ★★★ VERIFICAÇÃO mounted APÓS await ★★★
      if (mounted) {
        setState(() { _stockItems = items; _isLoading = false; });
        debugPrint("[StockScreen] Itens carregados: ${items.length}");
      }
    } catch (e) {
      // ★★★ VERIFICAÇÃO mounted APÓS await (implícito no catch) ★★★
      if (mounted) {
        setState(() { _errorMessage = e.toString(); _isLoading = false; _stockItems = []; });
         debugPrint("[StockScreen] Erro ao carregar itens: $e");
      }
    }
  }

  // Garante que o ApiService tem o token atual do AuthProvider
  bool _ensureApiServiceToken() {
    // Usa listen: false pois é chamado em initState/ações
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      // ★★★ VERIFICAÇÃO mounted ANTES DE setState ★★★
      if (mounted) {
          // Evita chamar setState diretamente aqui se _loadStockItems já faz
          // Apenas define a mensagem de erro para ser mostrada no build
          _errorMessage = "Sessão inválida. Faça login.";
          // Garante que _isLoading seja false para exibir o erro
          if (_isLoading) _isLoading = false;
          // Força rebuild para mostrar erro se necessário (cuidado com loops)
          // setState((){}); // Descomentar com cautela
      }
      debugPrint("[StockScreen] _ensureApiServiceToken: Falha - Usuário não autenticado.");
      return false;
    }
    _apiService.setAuthToken(token); // Define token no serviço
    return true;
  }

  // Navega para a tela de adição/edição de item
  Future<void> _navigateToEditItem(int storeId, {StockItem? item}) async {
    // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context (Navigator) ★★★
    if (!mounted) return;
    if (!_ensureApiServiceToken()) return;

    final result = await Navigator.push<bool>( // await
      context,
      MaterialPageRoute(
        builder: (context) => EditStockItemScreen(storeId: storeId, initialItem: item),
      ),
    );

    // ★★★ VERIFICAÇÃO mounted APÓS await (pop da tela de edição) ★★★
    if (result == true && mounted) {
      _showSnackbar("Operação realizada. Atualizando lista...", Colors.green);
      // Recarrega usando o storeId atual (já deve estar correto)
      if (_currentStoreId != null) {
        // showLoading: false para não mostrar o indicator central, só o RefreshIndicator se puxar
        _loadStockItems(storeId: _currentStoreId!, showLoading: false);
      }
    }
  }

  // Navega para a tela de importação em massa
  Future<void> _navigateToBulkImport() async {
    // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context ★★★
    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const BulkImportScreen(),
      ),
    );

    // ★★★ VERIFICAÇÃO mounted APÓS await ★★★
    if (result == true && mounted) {
      _showSnackbar("Importação concluída. Atualizando lista...", Colors.green);
      // Recarrega a lista se houve sucesso na importação
      if (_currentStoreId != null) {
        _loadStockItems(storeId: _currentStoreId!, showLoading: false);
      }
    }
  }

  // Exibe uma SnackBar
  void _showSnackbar(String message, [Color? backgroundColor]) {
    // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context ★★★
    if (!mounted) return;
    
    if (backgroundColor == Colors.green) {
      ErrorHandler.showSuccessSnackBar(context, message);
    } else if (backgroundColor == Colors.red || backgroundColor == Colors.orange) {
      ErrorHandler.showErrorSnackBar(context, message);
    } else {
      // Use default success for general messages
      ErrorHandler.showSuccessSnackBar(context, message);
    }
  }

  // Constrói a view baseada no tipo de layout selecionado
  Widget _buildLayoutBasedView(int currentStoreId, LayoutType layoutType) {
    switch (layoutType) {
      case LayoutType.list:
        return _buildListView(currentStoreId);
      case LayoutType.grid:
        return _buildGridView(currentStoreId);
      case LayoutType.card:
        return _buildCardView(currentStoreId);
    }
  }

  // Constrói uma visualização em cards (mais detalhada que grid)
  Widget _buildCardView(int currentStoreId) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _stockItems.length,
      itemBuilder: (context, index) {
        final item = _stockItems[index];
        final imageUrl = item.imageUrl;
        final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: InkWell(
              onTap: () => _navigateToEditItem(currentStoreId, item: item),
              child: Row(
                children: [
                  // Imagem do produto
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        if (hasImage)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image, color: Colors.grey);
                              },
                            ),
                          )
                        else
                          const Center(
                            child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40),
                          ),
                        if (hasImage)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.7),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8.0),
                                  bottomRight: Radius.circular(8.0),
                                ),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.photo,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Informações do produto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quantidade: ${_formatQuantity(item.quantity)} ${item.properties['unit'] ?? 'UN'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Categoria: ${item.properties[AppPrefs.propCategory] ?? 'N/A'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.properties['barcode'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Código: ${item.properties['barcode']}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Ícone de navegação
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Remove métodos antigos não utilizados
  // Alterna o layout e salva a preferência (método obsoleto - mantido para compatibilidade)
  void _toggleLayout() {
    // Este método não é mais usado, mas mantido para evitar erros
    setState(() { _useCardLayout = !_useCardLayout; });
    AppPrefs.setUseCardLayout(_useCardLayout);
  }

  // Formata a quantidade
  String _formatQuantity(double quantity) {
    return quantity.toStringAsFixed(_quantityDecimals);
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Assiste (watch) para reagir a mudanças na loja selecionada
    final storeProvider = Provider.of<StoreProvider>(context);
    final layoutProvider = Provider.of<LayoutProvider>(context);
    final selectedStore = storeProvider.selectedStore;

    // Log para ajudar a entender o estado atual durante o build
    // debugPrint("[StockScreen build] isLoading: $_isLoading, error: $_errorMessage, selectedStore: ${selectedStore?.id}, items: ${_stockItems.length}");

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(selectedStore?.name ?? 'Nenhuma Loja'),
        actions: [ /* ... Ações como antes (já usam _isLoading) ... */
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Mais opções',
            enabled: selectedStore != null && !_isLoading,
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _navigateToBulkImport();
                  break;
                case 'refresh':
                  _loadStockItems(storeId: selectedStore!.id);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_upload),
                    SizedBox(width: 8),
                    Text('Importar Mercadorias'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Atualizar Lista'),
                  ],
                ),
              ),
            ],
          ),
          IconButton( 
            icon: Icon(layoutProvider.stockLayoutType == LayoutType.list ? Icons.view_module_outlined : Icons.view_list_outlined), 
            tooltip: 'Alternar Layout', 
            onPressed: () {
              final nextLayout = layoutProvider.stockLayoutType == LayoutType.list 
                  ? LayoutType.grid 
                  : LayoutType.list;
              layoutProvider.setStockLayoutType(nextLayout);
            },
          ),

        ],
      ),
      body: _buildBody(selectedStore, layoutProvider), // Passa a loja selecionada e layout provider para o método de build do corpo
      floatingActionButton: selectedStore == null
          ? null
          : FloatingActionButton(
              onPressed: _isLoading ? null : () => _navigateToEditItem(selectedStore.id),
              tooltip: 'Adicionar Item',
              child: const Icon(Icons.add),
            ),
    );
  }

  // --- Build Helpers ---

  // Constrói o Drawer (sem mudanças significativas, adicionando consts)
  Widget _buildAppDrawer(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final userName = user?.name ?? 'Usuário';
    final userEmail = user?.email ?? '';
    final stores = storeProvider.stores;
    final selectedStore = storeProvider.selectedStore;

    return Drawer( child: ListView( padding: EdgeInsets.zero, children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white70,
              child: Text(
                userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 40.0, color: Colors.indigo),
              ),
            ),
          ),
          const ListTile(title: Text('Lojas', style: TextStyle(fontWeight: FontWeight.bold))),
          if (storeProvider.isLoading && stores.isEmpty) const ListTile(leading: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)), title: Text("Carregando..."))
          else if (stores.isEmpty) ListTile( leading: const Icon(Icons.warning_amber_rounded), title: const Text("Nenhuma loja."), subtitle: const Text("Crie uma em 'Gerenciar'."), onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.storeManagement); }, ),
          ...stores.map((store) => ListTile( title: Text(store.name), leading: Icon(store.id == selectedStore?.id ? Icons.storefront : Icons.store_outlined), selected: store.id == selectedStore?.id, selectedTileColor: Colors.indigo.withOpacity(0.1), onTap: () { if (store.id != selectedStore?.id) { storeProvider.selectStore(store); } Navigator.pop(context); }, )),
          const Divider(),
          ListTile( leading: const Icon(Icons.add_business_outlined), title: const Text('Gerenciar Lojas'), onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.storeManagement); },),
          const Divider(),
          const ListTile(title: Text('Outros Menus', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile( leading: const Icon(Icons.settings_outlined), title: const Text('Configurações'), onTap: () { Navigator.pop(context); _showSnackbar("Configurações ainda não implementadas", Colors.orange); },),
          ListTile( leading: const Icon(Icons.receipt_long_outlined), title: const Text('Documentos'), onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.documentList);},),
          ListTile( leading: const Icon(Icons.assessment_outlined), title: const Text('Relatórios'), onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.reports); },),
          const Divider(),
        ],
      ),
    );
  }

  // Constrói o corpo principal
  Widget _buildBody(Store? selectedStore, LayoutProvider layoutProvider) {
    if (selectedStore == null) { return const Center(child: Padding( padding: EdgeInsets.all(20.0), child: Text( 'Selecione uma loja no menu lateral para visualizar o estoque ou crie uma nova em "Gerenciar Lojas".', textAlign: TextAlign.center, ),)); }
    if (_isLoading && _stockItems.isEmpty) { return const Center(child: CircularProgressIndicator()); }
    if (_errorMessage != null) { return Center( child: Padding( padding: const EdgeInsets.all(16.0), child: Column( mainAxisSize: MainAxisSize.min, children: [ const Icon(Icons.error_outline, color: Colors.red, size: 48), const SizedBox(height: 16), Text('Erro ao carregar dados:', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700])), const SizedBox(height: 20), ElevatedButton.icon( icon: const Icon(Icons.refresh), label: const Text('Tentar Novamente'), onPressed: () => _loadStockItems(storeId: selectedStore.id), ) ]))); }
    if (_stockItems.isEmpty) { return Center( child: Text( 'Nenhum item cadastrado nesta loja (${selectedStore.name}).\nUse o botão "+" para adicionar.', textAlign: TextAlign.center, )); }

    // Lista ou Grid baseado no LayoutProvider
    return RefreshIndicator(
      onRefresh: () => _loadStockItems(storeId: selectedStore.id, showLoading: false),
      child: _buildLayoutBasedView(selectedStore.id, layoutProvider.stockLayoutType),
    );
  }

  // Constrói ListView (com correção no CircleAvatar)
  Widget _buildListView(int currentStoreId) {
    return ListView.builder(
      itemCount: _stockItems.length,
      itemBuilder: (context, index) {
        final item = _stockItems[index];
        final imageUrl = item.imageUrl;
        final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
        // Log para verificar properties
        // debugPrint("[StockScreen List] Renderizando Item ID: ${item.id}, Props: ${item.properties}");
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
            onBackgroundImageError: hasImage ? (e, s) { /* Log opcional */ } : null,
            child: !hasImage ? const Icon(Icons.inventory_2_outlined, color: Colors.grey) : null,
          ),
          title: Text(item.name),
          // Acessa categoria de properties e formata quantidade
          subtitle: Text('Qtd: ${_formatQuantity(item.quantity)} | Cat: ${item.properties[AppPrefs.propCategory] ?? 'N/A'}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToEditItem(currentStoreId, item: item),
        );
      },
    );
  }

  // Constrói GridView (com correção na imagem)
  Widget _buildGridView(int currentStoreId) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth / 180).floor();
    crossAxisCount = crossAxisCount < 2 ? 2 : crossAxisCount;

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount, crossAxisSpacing: 8.0, mainAxisSpacing: 8.0, childAspectRatio: 0.8,
      ),
      itemCount: _stockItems.length,
      itemBuilder: (context, index) {
        final item = _stockItems[index];
        final imageUrl = item.imageUrl;
        final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
        // Log para verificar properties
        // debugPrint("[StockScreen Grid] Renderizando Item ID: ${item.id}, Props: ${item.properties}");
        return Card(
          clipBehavior: Clip.antiAlias, elevation: 2.0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          child: InkWell(
            onTap: () => _navigateToEditItem(currentStoreId, item: item),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded( 
                  flex: 3, 
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      hasImage
                        ? Image.network(
                            imageUrl, 
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) => progress == null 
                              ? child 
                              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorBuilder: (ctx, error, stack) { 
                              return Container(
                                color: Colors.grey[200], 
                                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))
                              ); 
                            }
                          )
                        : Container(
                            color: Colors.grey[200], 
                            child: const Center(child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40))
                          ),
                      if (hasImage)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.7),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8.0),
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.photo,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded( flex: 2, child: Padding( padding: const EdgeInsets.all(8.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(item.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('Qtd: ${_formatQuantity(item.quantity)}', style: Theme.of(context).textTheme.bodySmall),
                      Text('Cat: ${item.properties[AppPrefs.propCategory] ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                    ],),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} // Fim da classe _StockScreenState