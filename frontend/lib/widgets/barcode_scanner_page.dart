import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatelessWidget {
  const BarcodeScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código de Barras'),
      ),
      body: MobileScanner(
        allowDuplicates: false,
        onDetect: (Barcode barcode, MobileScannerArguments? args) {
          final code = barcode.rawValue;
          if (code != null && context.mounted) {
            Navigator.of(context).pop(code);
          }
        },
      ),
    );
  }
}
