// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import '../main.dart'; // Para AppRoutes
import '../utils/app_prefs.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;
  String? _selectedCompany;
  String? _selectedBranch;
  String? _selectedWarehouse;
  final List<String> _companies = ['Company A', 'Company B'];
  final List<String> _branches = ['Branch 1', 'Branch 2'];
  final List<String> _warehouses = ['Warehouse 1', 'Warehouse 2'];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    setState(() => _isLoading = true);
    try {
      final company = await AppPrefs.getSelectedCompany();
      final branch = await AppPrefs.getSelectedBranch();
      final warehouse = await AppPrefs.getSelectedWarehouse();
      
      if (mounted) {
        setState(() {
          _selectedCompany = company;
          _selectedBranch = branch;
          _selectedWarehouse = warehouse;
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePreferencesAndContinue() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Save all preferences
      await AppPrefs.savePreferences(
        selectedCompany: _selectedCompany ?? '',
        selectedBranch: _selectedBranch,
        selectedWarehouse: _selectedWarehouse,
        firstLaunch: false, // Set to false since we're completing the welcome flow
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Preferências salvas com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to home screen
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Erro ao salvar preferências: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bem-vindo'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Configure suas preferências',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecione sua empresa, filial e armazém para começar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Company Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCompany,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.business),
                    labelText: 'Empresa',
                  ),
                  items: _companies.map((company) => DropdownMenuItem(
                    value: company,
                    child: Text(company),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedCompany = value),
                  validator: (value) => value == null || value.isEmpty ? 'Selecione uma empresa' : null,
                ),
                const SizedBox(height: 16),

                // Branch Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedBranch,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_city),
                    labelText: 'Filial',
                  ),
                  items: _branches.map((branch) => DropdownMenuItem(
                    value: branch,
                    child: Text(branch),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedBranch = value),
                  validator: (value) => value == null || value.isEmpty ? 'Selecione uma filial' : null,
                ),
                const SizedBox(height: 16),

                // Warehouse Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedWarehouse,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.warehouse),
                    labelText: 'Armazém',
                  ),
                  items: _warehouses.map((warehouse) => DropdownMenuItem(
                    value: warehouse,
                    child: Text(warehouse),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedWarehouse = value),
                  validator: (value) => value == null || value.isEmpty ? 'Selecione um armazém' : null,
                ),
                const Spacer(),

                // Continue Button
                ElevatedButton(
                  onPressed: !_isLoading && _formKey.currentState!.validate()
                      ? _savePreferencesAndContinue
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}