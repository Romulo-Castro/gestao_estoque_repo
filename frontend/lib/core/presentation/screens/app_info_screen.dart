// lib/core/presentation/screens/app_info_screen.dart
import 'package:flutter/material.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informações do App'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sistema de Gestão de Estoque',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Versão 1.0.0'),
            SizedBox(height: 8),
            Text('Desenvolvido com Flutter'),
          ],
        ),
      ),
    );
  }
}
