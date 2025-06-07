// lib/screens/expenses_screen.dart
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesas'),
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wallet_outlined,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 24),
              Text(
                'Controle de Despesas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Esta funcionalidade permitirá o controle completo de despesas, incluindo:\n\n'
                '• Registro de despesas operacionais\n'
                '• Categorização por tipo de despesa\n'
                '• Relatórios de gastos mensais\n'
                '• Controle de orçamento\n'
                '• Análise de custos por loja\n\n'
                'Em breve disponível!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
