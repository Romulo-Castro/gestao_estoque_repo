// lib/screens/help_screen.dart
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda'),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHelpSection(
            'Primeiros Passos',
            Icons.rocket_launch_outlined,
            [
              'Crie sua primeira loja em "Gerenciar Lojas"',
              'Selecione a loja criada no seletor da tela inicial',
              'Cadastre grupos de itens para organizar seu estoque',
              'Adicione produtos através da tela "Mercadorias"',
              'Use "Importar Excel/CSV" para adicionar produtos em lote',
            ],
          ),
          const SizedBox(height: 24),
          _buildHelpSection(
            'Gerenciamento de Estoque',
            Icons.inventory_2_outlined,
            [
              'Use "Nova Entrada" para registrar compras e ajustes positivos',
              'Use "Nova Saída" para registrar vendas e ajustes negativos',
              'O scanner de código de barras permite busca rápida de produtos',
              'Visualize relatórios para acompanhar movimentações',
            ],
          ),
          const SizedBox(height: 24),
          _buildHelpSection(
            'Importação de Dados',
            Icons.file_upload_outlined,
            [
              'Prepare seu arquivo Excel/CSV com as colunas: Nome, Código, Grupo, Quantidade, Preço',
              'Acesse "Importar Excel/CSV" no menu ou tela inicial',
              'Selecione seu arquivo e siga as instruções na tela',
              'Verifique os dados antes de confirmar a importação',
            ],
          ),
          const SizedBox(height: 24),
          _buildHelpSection(
            'Relatórios e Análises',
            Icons.assessment_outlined,
            [
              'Acesse relatórios detalhados de estoque e movimentações',
              'Visualize gráficos de entrada e saída de produtos',
              'Acompanhe o desempenho por loja',
              'Exporte dados para análises externas',
            ],
          ),
          const SizedBox(height: 24),
          _buildHelpSection(
            'Suporte Técnico',
            Icons.support_agent_outlined,
            [
              'Para dúvidas técnicas, consulte a documentação completa',
              'Em caso de problemas, verifique sua conexão com a internet',
              'Mantenha o aplicativo sempre atualizado',
              'Entre em contato com o suporte para assistência especializada',
            ],
          ),
          const SizedBox(height: 32),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sistema de Gestão de Estoque',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Versão 1.0.0',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Desenvolvido para facilitar o controle e gerenciamento de estoque em pequenas e médias empresas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
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

  Widget _buildHelpSection(String title, IconData icon, List<String> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14),
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
}
