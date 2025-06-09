// lib/core/presentation/screens/bulk_import_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/import_result.dart';
import '../../../shared/services/bulk_import_service.dart';
import '../providers/store_provider.dart';
import '../../../shared/utils/error_handler.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  late BulkImportService _importService; // Declarado como late
  
  bool _isImporting = false;
  File? _selectedFile;
  ImportResult? _lastImportResult;
  String _importProgress = '';

  @override
  void initState() {
    super.initState();
    // Obter ApiService do StoreProvider e inicializar BulkImportService
    // É crucial que StoreProvider já tenha o ApiService configurado com o token.
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    _importService = BulkImportService(storeProvider.apiService);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importação de Mercadorias'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informações sobre o formato do arquivo
            _buildFormatInfoCard(),
            const SizedBox(height: 16),
            
            // Seleção do arquivo
            _buildFileSelectionCard(),
            const SizedBox(height: 16),
            
            // Botões de ação
            _buildActionButtons(),
            const SizedBox(height: 16),
            
            // Progresso da importação
            if (_isImporting) _buildProgressCard(),
            
            // Resultados da última importação
            if (_lastImportResult != null) _buildResultsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Formato do Arquivo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text(
              'O arquivo deve ser Excel (.xlsx) ou CSV (.csv) com as seguintes colunas:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildColumnList(),
            const SizedBox(height: 8),
            const Text(
              '* Campos obrigatórios\n\n'
              'A primeira linha deve conter os cabeçalhos das colunas.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnList() {
    const columns = [
      {'name': 'Nome*', 'desc': 'Nome da mercadoria'},
      {'name': 'Quantidade*', 'desc': 'Quantidade em estoque'},
      {'name': 'Código de Barras', 'desc': 'Código de barras (opcional)'},
      {'name': 'Categoria', 'desc': 'Categoria do produto (opcional)'},
      {'name': 'Descrição', 'desc': 'Descrição detalhada (opcional)'},
      {'name': 'Preço de Custo', 'desc': 'Preço de custo (opcional)'},
      {'name': 'Preço de Venda', 'desc': 'Preço de venda (opcional)'},
      {'name': 'Unidade', 'desc': 'Unidade de medida (opcional)'},
      {'name': 'Fornecedor', 'desc': 'Nome do fornecedor (opcional)'},
      {'name': 'Localização', 'desc': 'Localização no estoque (opcional)'},
      {'name': 'Observações', 'desc': 'Observações gerais (opcional)'},
    ];

    return Column(
      children: columns.map((col) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                col['name']!,
                style: TextStyle(
                  fontWeight: col['name']!.contains('*') ? FontWeight.bold : FontWeight.normal,
                  color: col['name']!.contains('*') ? Colors.red[700] : null,
                ),
              ),
            ),
            Expanded(
              child: Text(
                col['desc']!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildFileSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.file_upload_outlined),
                const SizedBox(width: 8),
                Text(
                  'Selecionar Arquivo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (_selectedFile == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    const Text(
                      'Nenhum arquivo selecionado',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isImporting ? null : _selectFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Escolher Arquivo'),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[300]!),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.path.split('/').last,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _getFileSize(_selectedFile!),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isImporting ? null : () {
                        setState(() {
                          _selectedFile = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      color: Colors.red[700],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final storeProvider = context.watch<StoreProvider>();
    final selectedStore = storeProvider.selectedStore;
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_selectedFile == null || _isImporting || selectedStore == null) 
                ? null 
                : _startImport,
            icon: _isImporting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download),
            label: Text(_isImporting ? 'Importando...' : 'Iniciar Importação'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _downloadTemplate,
          icon: const Icon(Icons.download),
          label: const Text('Template'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Importando...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_importProgress.isNotEmpty)
              Text(_importProgress),
          ],
        ),
      ),
    );
  }
  Widget _buildResultsCard() {
    final result = _lastImportResult!;
    final hasErrors = result.errorCount > 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasErrors ? Icons.error_outline : Icons.check_circle_outline,
                  color: hasErrors ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resultado da Importação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            
            // Resumo estatístico
            _buildStatRow('Total de linhas processadas:', result.totalRows.toString()),
            _buildStatRow('Importadas com sucesso:', '${result.successCount}', Colors.green),
            if (result.errorCount > 0)
              _buildStatRow('Erros:', '${result.errorCount}', Colors.red),
            if (result.warnings.isNotEmpty)
              _buildStatRow('Avisos:', '${result.warnings.length}', Colors.orange),
            
            // Lista de erros
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Erros:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              ...result.errors.take(5).map((error) => Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                child: Text(
                  '• $error',
                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                ),
              )),
              if (result.errors.length > 5)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '... e mais ${result.errors.length - 5} erros',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
            ],
            
            // Lista de avisos
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Avisos:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              ...result.warnings.take(3).map((warning) => Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                child: Text(
                  '• $warning',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
              )),
              if (result.warnings.length > 3)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '... e mais ${result.warnings.length - 3} avisos',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );
      
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _lastImportResult = null; // Limpa resultado anterior
        });
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Erro ao selecionar arquivo: $e');
    }
  }

  Future<void> _startImport() async {
    if (_selectedFile == null) return;
    
    final storeProvider = context.read<StoreProvider>();
    final selectedStore = storeProvider.selectedStore;
    
    if (selectedStore == null) {
      ErrorHandler.showErrorSnackBar(context, 'Nenhuma loja selecionada');
      return;
    }

    setState(() {
      _isImporting = true;
      _importProgress = 'Iniciando importação...';
      _lastImportResult = null;
    });

    try {
      // Determina o tipo de arquivo pela extensão
      final isExcel = _selectedFile!.path.toLowerCase().endsWith('.xlsx');
      
      setState(() {
        _importProgress = isExcel 
            ? 'Processando arquivo Excel...' 
            : 'Processando arquivo CSV...';
      });

      ImportResult result;
      if (isExcel) {
        result = await _importService.importFromExcel(_selectedFile!, selectedStore.id);
      } else {
        result = await _importService.importFromCsv(_selectedFile!, selectedStore.id);
      }

      if (mounted) {
        setState(() {
          _lastImportResult = result;
          _importProgress = '';
        });

        // Mostra feedback ao usuário
        if (result.errorCount == 0) {
          ErrorHandler.showSuccessSnackBar(
            context, 
            'Importação concluída! ${result.successCount} itens importados.'
          );
        } else if (result.successCount > 0) {
          ErrorHandler.showErrorSnackBar(
            context,
            'Importação parcial: ${result.successCount} sucessos, ${result.errorCount} erros.'
          );
        } else {
          ErrorHandler.showErrorSnackBar(
            context,
            'Importação falhou: ${result.errorCount} erros encontrados.'
          );
        }

        // Se houve pelo menos alguns sucessos, sinaliza para atualizar a lista
        if (result.successCount > 0) {
          Navigator.of(context).pop(true); // Retorna true para indicar sucesso
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _importProgress = '';
        });
        ErrorHandler.showErrorSnackBar(context, 'Erro durante a importação: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
  void _downloadTemplate() {
    // Show template options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Template de Importação'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_importService.getImportTemplateDescription()),
                const SizedBox(height: 16),
                const Text(
                  'Escolha o formato do template:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Excel Template Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _downloadExcelTemplate();
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Download Template Excel (.xlsx)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // CSV Template Button  
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _downloadCsvTemplate();
                    },
                    icon: const Icon(Icons.description),
                    label: const Text('Download Template CSV (.csv)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Exemplo de conteúdo:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    _importService.generateSampleCsvContent(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadExcelTemplate() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Gerando template Excel...'),
            ],
          ),
        ),
      );

      // Generate Excel template
      final templateFile = await _importService.generateExcelTemplate();
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          downloadsDir = Directory('$userProfile\\Downloads');
        }
      } else {
        downloadsDir = await getDownloadsDirectory();
      }
      
      if (downloadsDir == null || !await downloadsDir.exists()) {
        // Fallback to documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      // Copy file to downloads
      final fileName = 'template_importacao_mercadorias_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final targetFile = File('${downloadsDir.path}/$fileName');
      await templateFile.copy(targetFile.path);

      // Clean up temp file
      await templateFile.delete();

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context, 
          'Template Excel salvo em: ${targetFile.path}'
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context, 
          'Erro ao gerar template Excel: $e'
        );
      }
    }
  }

  Future<void> _downloadCsvTemplate() async {
    try {
      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          downloadsDir = Directory('$userProfile\\Downloads');
        }
      } else {
        downloadsDir = await getDownloadsDirectory();
      }
      
      if (downloadsDir == null || !await downloadsDir.exists()) {
        // Fallback to documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      // Generate CSV content
      final csvContent = _importService.generateSampleCsvContent();
      
      // Save CSV file
      final fileName = 'template_importacao_mercadorias_${DateTime.now().millisecondsSinceEpoch}.csv';
      final targetFile = File('${downloadsDir.path}/$fileName');
      await targetFile.writeAsString(csvContent);

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context, 
          'Template CSV salvo em: ${targetFile.path}'
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context, 
          'Erro ao salvar template CSV: $e'
        );
      }
    }
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
