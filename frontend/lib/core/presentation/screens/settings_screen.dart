// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../providers/layout_provider.dart';
import '../../../shared/utils/app_prefs.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _useLocalStorage = true;
  bool _showNotifications = true;
  bool _isLoading = false;
  String _appVersion = '1.0.0';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Carregar configurações do AppPrefs
      _isDarkMode = await AppPrefs.getBool('darkMode') ?? false;
      _useLocalStorage = await AppPrefs.getBool('useLocalStorage') ?? true;
      _showNotifications = await AppPrefs.getBool('showNotifications') ?? true;
      
      // Simular carregamento da versão do app
      await Future.delayed(const Duration(milliseconds: 300));
      _appVersion = '1.0.0';
    } catch (e) {
      debugPrint('Erro ao carregar configurações: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Salvar configurações no AppPrefs
      await AppPrefs.setBool('darkMode', _isDarkMode);
      await AppPrefs.setBool('useLocalStorage', _useLocalStorage);
      await AppPrefs.setBool('showNotifications', _showNotifications);
      
      // Mostrar confirmação
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar configurações: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar configurações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redefinir Configurações'),
        content: const Text('Tem certeza que deseja redefinir todas as configurações para os valores padrão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Redefinir'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isDarkMode = false;
        _useLocalStorage = true;
        _showNotifications = true;
      });
      
      await _saveSettings();
    }
  }
  
  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Cache'),
        content: const Text('Tem certeza que deseja limpar o cache do aplicativo? Isso não afetará seus dados salvos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      // Simular limpeza de cache
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache limpo com sucesso!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.name ?? 'Usuário';
    final userEmail = authProvider.user?.email ?? '';
    final selectedStoreName = storeProvider.selectedStore?.name ?? 'Nenhuma loja selecionada';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Salvar configurações',
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção de Perfil
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Perfil',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo,
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(userName),
                            subtitle: Text(userEmail),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Edição de perfil será implementada em breve!'),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.store),
                            title: const Text('Loja Atual'),
                            subtitle: Text(selectedStoreName),
                            trailing: IconButton(
                              icon: const Icon(Icons.swap_horiz),
                              onPressed: () {
                                Navigator.pushNamed(context, '/store-management');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Seção de Aparência
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aparência',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          SwitchListTile(
                            title: const Text('Modo Escuro'),
                            subtitle: const Text('Ativar tema escuro no aplicativo'),
                            value: _isDarkMode,
                            onChanged: (value) {
                              setState(() {
                                _isDarkMode = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Seção de Layout
                  Consumer<LayoutProvider>(
                    builder: (context, layoutProvider, child) {
                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Preferências de Layout',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('Layout do Estoque'),
                                subtitle: Text(layoutProvider.stockLayoutType.displayName),
                                trailing: DropdownButton<LayoutType>(
                                  value: layoutProvider.stockLayoutType,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onChanged: (LayoutType? newValue) {
                                    if (newValue != null) {
                                      layoutProvider.setStockLayoutType(newValue);
                                    }
                                  },
                                  items: LayoutType.values.map<DropdownMenuItem<LayoutType>>((LayoutType value) {
                                    return DropdownMenuItem<LayoutType>(
                                      value: value,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(value.icon, size: 16),
                                          const SizedBox(width: 8),
                                          Text(value.displayName),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              ListTile(
                                title: const Text('Layout dos Documentos'),
                                subtitle: Text(layoutProvider.documentLayoutType.displayName),
                                trailing: DropdownButton<LayoutType>(
                                  value: layoutProvider.documentLayoutType,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onChanged: (LayoutType? newValue) {
                                    if (newValue != null) {
                                      layoutProvider.setDocumentLayoutType(newValue);
                                    }
                                  },
                                  items: LayoutType.values.map<DropdownMenuItem<LayoutType>>((LayoutType value) {
                                    return DropdownMenuItem<LayoutType>(
                                      value: value,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(value.icon, size: 16),
                                          const SizedBox(width: 8),
                                          Text(value.displayName),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              ListTile(
                                title: const Text('Layout dos Clientes'),
                                subtitle: Text(layoutProvider.customerLayoutType.displayName),
                                trailing: DropdownButton<LayoutType>(
                                  value: layoutProvider.customerLayoutType,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onChanged: (LayoutType? newValue) {
                                    if (newValue != null) {
                                      layoutProvider.setCustomerLayoutType(newValue);
                                    }
                                  },
                                  items: LayoutType.values.map<DropdownMenuItem<LayoutType>>((LayoutType value) {
                                    return DropdownMenuItem<LayoutType>(
                                      value: value,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(value.icon, size: 16),
                                          const SizedBox(width: 8),
                                          Text(value.displayName),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              ListTile(
                                title: const Text('Layout dos Fornecedores'),
                                subtitle: Text(layoutProvider.supplierLayoutType.displayName),
                                trailing: DropdownButton<LayoutType>(
                                  value: layoutProvider.supplierLayoutType,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onChanged: (LayoutType? newValue) {
                                    if (newValue != null) {
                                      layoutProvider.setSupplierLayoutType(newValue);
                                    }
                                  },
                                  items: LayoutType.values.map<DropdownMenuItem<LayoutType>>((LayoutType value) {
                                    return DropdownMenuItem<LayoutType>(
                                      value: value,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(value.icon, size: 16),
                                          const SizedBox(width: 8),
                                          Text(value.displayName),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Seção de Dados
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dados e Armazenamento',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          SwitchListTile(
                            title: const Text('Armazenamento Local'),
                            subtitle: const Text('Manter cópia dos dados no dispositivo'),
                            value: _useLocalStorage,
                            onChanged: (value) {
                              setState(() {
                                _useLocalStorage = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Notificações'),
                            subtitle: const Text('Receber alertas de estoque baixo'),
                            value: _showNotifications,
                            onChanged: (value) {
                              setState(() {
                                _showNotifications = value;
                              });
                            },
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text('Limpar Cache'),
                            subtitle: const Text('Remover dados temporários'),
                            trailing: const Icon(Icons.cleaning_services_outlined),
                            onTap: _clearCache,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Seção de Sobre
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sobre',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text('Versão do Aplicativo'),
                            subtitle: Text(_appVersion),
                            trailing: const Icon(Icons.info_outline),
                          ),
                          ListTile(
                            title: const Text('Termos de Uso'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Termos de uso serão implementados em breve!'),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            title: const Text('Política de Privacidade'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Política de privacidade será implementada em breve!'),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            title: const Text('Informações do App'),
                            subtitle: const Text('Dados técnicos e diagnóstico'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.pushNamed(context, '/app-info');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botões de Ação
                  Center(
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.restore),
                          label: const Text('Redefinir Configurações'),
                          onPressed: _resetSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Sair da Conta'),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Sair da Conta'),
                                content: const Text('Tem certeza que deseja sair da sua conta?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Sair'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true && mounted) {
                              await authProvider.logout();
                              // Navega explicitamente para a tela de login
                              if (mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context, 
                                  '/login', 
                                  (route) => false // Remove todas as rotas anteriores
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
