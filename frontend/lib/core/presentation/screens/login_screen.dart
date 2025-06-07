// lib/core/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/utils/app_routes.dart';

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
    
    // Mostrar indicador de loading
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Realizando login...'), duration: Duration(seconds: 2)),
      );
    }

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      authProvider.clearError();
      // Reset navigation to root so AuthWrapper can redirect appropriately
      if (context.mounted) {
        // Remover snackbar anterior
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
      }
    } else if (context.mounted) {
      // Mostrar erro específico
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro no login: ${authProvider.error ?? "Falha na autenticação"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    // If login failed, AuthProvider.error is shown via Consumer
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
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
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
                    Navigator.of(context).pushNamed(AppRoutes.register);
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