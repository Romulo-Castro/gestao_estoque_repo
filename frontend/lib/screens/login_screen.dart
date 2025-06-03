// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // Ajuste o caminho se necessário

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save(); // Garante que os valores mais recentes sejam usados

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // DEBUG: Imprima aqui para ver se o método está sendo chamado
    print("LoginScreen: Tentando fazer login com: ${_emailController.text.trim()}");

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    // DEBUG: Imprima o valor de success
    print("LoginScreen: Status do login (success): $success");
    print("LoginScreen: Widget está montado (mounted): $mounted");

    if (success && mounted) {
      print("LoginScreen: Navegando para /home"); // DEBUG
      // Limpa o erro anterior, caso exista, antes de navegar
      authProvider.clearError();
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // DEBUG: O que aconteceu se não navegou?
      if (!success) {
        print("LoginScreen: Login falhou (success == false). Erro do AuthProvider: ${authProvider.error}");
      }
      if (!mounted) {
        print("LoginScreen: Widget não está montado após o login");
      }
      // A mensagem de erro já deve ser exibida pelo Consumer do AuthProvider
    }
  }

  @override
  Widget build(BuildContext context) {
    // Não precisa do Provider.of aqui se você só o usa no _submit
    // Mas se você tem um Consumer<AuthProvider> para mostrar o authProvider.isLoading ou authProvider.error, mantenha-o.

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Gestão de Estoques',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Por favor, insira um email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                Consumer<AuthProvider>( // Para exibir erros e estado de loading
                  builder: (ctx, authProvider, _) {
                    if (authProvider.error != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          authProvider.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink(); // Não mostra nada se não houver erro
                  },
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>( // Para o botão de loading
                  builder: (ctx, authProvider, _) => ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      // minimumSize: Size(double.infinity, 50), // Para ocupar toda a largura
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Limpar erro ao navegar para registro
                    Provider.of<AuthProvider>(context, listen: false).clearError();
                    Navigator.of(context).pushNamed('/register');
                  },
                  child: const Text('Não tem uma conta? Registre-se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}