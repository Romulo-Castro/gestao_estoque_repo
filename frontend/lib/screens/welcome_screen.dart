// lib/screens/welcome_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_prefs.dart';
import '../main.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // câmera picker
  final ImagePicker _picker = ImagePicker();

  // Step 2 switches
  final Map<String, bool> _properties = {
    'Nome': true,
    'Tags': true,
    'Código de Barras': true,
    'Descrição': true,
    'Unidade de Medida': true,
    'Imagem': true,
  };  
  int _decimalDigits = 0;

  // Step 5 dropdown
  final List<String> _readers = ['Câmara (Mobile Vision)'];
  String _selectedReader = 'Câmara (Mobile Vision)';

  void _next() {
    if (_currentIndex < 4) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    // Mark first launch completed
    await AppPrefs.setFirstLaunchCompleted(false);
    // Save selected item properties
    await AppPrefs.setItemProperties(
      _properties.entries.where((e) => e.value).map((e) => e.key).toList(),
    );
    // Save decimal digits setting
    await AppPrefs.setQuantityDecimals(_decimalDigits);
    // Save reader preference
    await AppPrefs.setString('reader', _selectedReader);
    // Save sale/purchase usage preference
    // await AppPrefs.setBool('use_sale_purchase', _useSalePurchase ?? false);
    // Navigate to home
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final active = i == _currentIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0), width: 10, height: 10,
          decoration: BoxDecoration(color: active ? Colors.white : Colors.lightGreen.withOpacity(0.4), shape: BoxShape.circle),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[600],
      body: SafeArea(
        child: Stack(children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: [
              // Step 1
              _step1(),
              // Step 2
              _step2(),
              // Step 3
              _step3(),
              // Step 4
              _step4(),
              // Step 5
              _step5(),
            ],
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: _buildDots(),
          ),
          Positioned(
            bottom: 16, right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.teal[900],
              elevation: 2,
              onPressed: _next,
              child: Icon(
                _currentIndex < 4 ? Icons.arrow_forward : Icons.check,
                color: Colors.white,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _step1() {
    return _buildPage(
      icon: Icons.inventory_outlined,
      title: 'Bem-vindo!',
      body: 'Por favor, siga este assistente para iniciar rapidamente. Posteriormente, poderá alterar qualquer parâmetro em “Configurações”.',
    );
  }

  Widget _step2() {
    return _buildPage(
      icon: Icons.note_add_outlined,
      title: 'Selecione as propriedades das mercadorias que deseja usar:',
      bodyWidget: Column(
        children: [
          ..._properties.keys.map((key) => SwitchListTile(
                tileColor: Colors.transparent,
                title: Text(key, style: const TextStyle(color: Colors.white, fontSize: 18)),
                value: _properties[key]!,
                onChanged: (v) => setState(() => _properties[key] = v),
              )),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white70, // background adaptado
                labelText: 'Número de dígitos após o ponto decimal',
                labelStyle: TextStyle(color: Colors.black), // label agora preta
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() => _decimalDigits = int.tryParse(val) ?? 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step3() {
    return _buildPage(
      icon: null,
      title: 'Selecione a exibição padrão:',
      bodyWidget: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              indicator: BoxDecoration(
                color: Colors.teal[900],
                borderRadius: BorderRadius.circular(4),
              ),
              tabs: const [Tab(text: 'Lista'), Tab(text: 'Cartões')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(8),
                    children: List.generate(6, (i) {
                      final names = ['BonAqua','Coca-Cola','Fanta','KitKat','M&M’s','Mars'];
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.white24),
                        title: Text(names[i], style: const TextStyle(color: Colors.white)),
                        subtitle: const Text('Qtd: 1 • R\$ 9,99', style: TextStyle(color: Colors.white70)),
                        trailing: const Icon(Icons.tag, color: Colors.white70),
                      );
                    }),
                  ),
                  GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(8),
                    childAspectRatio: 3/2,
                    children: List.generate(6, (i) {
                      final names = ['BonAqua','Coca-Cola','Fanta','KitKat','M&M’s','Mars'];
                      return Card(
                        color: Colors.white24,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(names[i], style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            const Text('Qtd: 1 • R\$ 9,99', style: TextStyle(color: Colors.white70)),
                          ]),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step4() {
    return _buildPage(
      icon: Icons.table_chart,
      title: 'A aplicação permite importar e exportar de/para Excel',
      bodyWidget: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IMPORTANTE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Se deseja importar stock inicial – importe para “Documento de Entrada”.', style: TextStyle(color: Colors.white, fontSize: 16)),
          Text('Se deseja importar apenas a lista de mercadorias e as suas propriedades – importe para o ecrã “Mercadorias”.', style: TextStyle(color: Colors.white, fontSize: 16)),
          Text('Poderá configurar colunas do Excel em “Configurações → Importar e Exportar”.', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _step5() {
    return _buildPage(
      icon: Icons.qr_code_scanner,
      title: 'Se pretender ler códigos de barras, temos vários tipos de leitores.',
      bodyWidget: Column(children: [
        const Text('Pode selecionar o tipo que funciona melhor no seu dispositivo.', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedReader,
          decoration: const InputDecoration(
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
          dropdownColor: Colors.teal[600],
          items: _readers.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: (v) => setState(() => _selectedReader = v!),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[900]),
          onPressed: () async {
            final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
            if (picked != null) {
              showDialog(
                // ignore: use_build_context_synchronously
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.teal[600],
                  contentPadding: EdgeInsets.zero,
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    Align(alignment: Alignment.topRight, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop())),
                    Image.file(File(picked.path)),
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('FECHAR', style: TextStyle(color: Colors.white))),
                  ]),
                ),
              );
            }
          },
          child: const Text('EXPERIMENTE AGORA'),
        ),
      ]),
    );
  }

  Widget _buildPage({IconData? icon, required String title, String? body, Widget? bodyWidget}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              margin: const EdgeInsets.only(top: 40, bottom: 24),
              child: Icon(icon, size: 180, color: Colors.white, shadows: const [Shadow(color: Colors.black26, blurRadius: 4)]),
            ),
          ],
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          if (body != null)
            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.white)),
          if (bodyWidget != null) ...[const SizedBox(height: 16), Expanded(child: bodyWidget)],
        ],
      ),
    );
  }
}