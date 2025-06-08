// lib/screens/edit_stock_item_screen.dart
import "dart:io";
import 'dart:math';
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "../../data/models/stock_item.dart";
import "../../data/models/item_group_model.dart"; // Importar modelo de grupo
import "../providers/auth_provider.dart";
import "../providers/item_group_provider.dart"; // Importar provider de grupo
import "../providers/store_provider.dart"; // Importar provider de loja
// Para obter storeId
import "../../data/datasources/api_service.dart";
import "../../../shared/utils/app_prefs.dart";
import "../../../shared/utils/error_handler.dart";
import "package:image_picker/image_picker.dart";
import '../widgets/barcode_scanner_page.dart';
import 'package:file_picker/file_picker.dart';

class EditStockItemScreen extends StatefulWidget {
  final int storeId;
  final StockItem? initialItem;

  const EditStockItemScreen({
    required this.storeId,
    super.key,
    this.initialItem,
  });

  @override
  State<EditStockItemScreen> createState() => _EditStockItemScreenState();
}

class _EditStockItemScreenState extends State<EditStockItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _picker = ImagePicker();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _categoryController; // Mantido por compatibilidade, mas grupo é preferível
  final Map<String, TextEditingController> _propControllers = {};

  // Estado para Grupo de Item
  ItemGroup? _selectedItemGroup;

  File? _selectedImageFile;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool get _isEditing => widget.initialItem != null;

  // Preferências
  List<String> _activeProperties = [];
  int _quantityDecimals = 0;

  // Helper to get display names for properties
  String _getPropertyDisplayName(String propKey) {
    // This should ideally come from a centralized place or i18n
    switch (propKey) {
      case AppPrefs.propDescription:
        return 'Descrição';
      case AppPrefs.propBarcode:
        return 'Código de Barras';
      case AppPrefs.propUom:
        return 'Unidade de Medida';
      case AppPrefs.propCategory:
        return 'Categoria';
      // Add other known keys
      default:
        // Capitalize first letter for unknown keys
        return propKey.isNotEmpty ? propKey[0].toUpperCase() + propKey.substring(1) : '';
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialItem?.name ?? "");
    _quantityController = TextEditingController(); 
    _categoryController = TextEditingController(); 

    _propControllers[AppPrefs.propDescription] = TextEditingController();
    _propControllers[AppPrefs.propBarcode] = TextEditingController();
    _propControllers[AppPrefs.propUom] = TextEditingController();
    
    _currentImageUrl = widget.initialItem?.imageUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureApiServiceToken();
      _loadPreferencesAndSetupControllers().then((_) {
        final groupProvider = Provider.of<ItemGroupProvider>(context, listen: false);
        // setStoreId is a void method, so no await here.
        // We assume that setStoreId will trigger a state change in ItemGroupProvider
        // which will then be picked up by a Consumer/Selector or by calling
        // _updateSelectedItemGroupFromProvider if needed after a short delay or via a listener.
        groupProvider.setStoreId(widget.storeId);
        // Call this after giving the provider a chance to update.
        // If groups are loaded asynchronously by setStoreId, this might need a more robust solution
        // like listening to ItemGroupProvider changes.
        Future.microtask(() {
          if (mounted) {
            _updateSelectedItemGroupFromProvider();
          }
        });
      });
    });
  }

  // Method to attempt setting the selected group
  void _updateSelectedItemGroupFromProvider() {
    final groupProvider = Provider.of<ItemGroupProvider>(context, listen: false);
    if (_isEditing && widget.initialItem?.groupId != null && groupProvider.groups.isNotEmpty) {
      try {
        final foundGroup = groupProvider.groups.firstWhere(
          (g) => g.id == widget.initialItem!.groupId,
        );
        // Check if it's actually a change to avoid unnecessary setState
        if (_selectedItemGroup?.id != foundGroup.id) {
          if (mounted) {
            setState(() {
              _selectedItemGroup = foundGroup;
            });
          }
        }
      } catch (e) {
        // If it was previously set but now not found, or never found
        if (mounted && _selectedItemGroup != null) { 
           setState(() {
             _selectedItemGroup = null;
           });
        }
        debugPrint("[EditStockItemScreen] Initial group ID ${widget.initialItem!.groupId} not found in provider groups during _updateSelectedItemGroupFromProvider.");
      }
    } else if (_isEditing && widget.initialItem?.groupId != null && _selectedItemGroup != null && groupProvider.groups.isEmpty && !groupProvider.isLoading) {
      // Groups became empty, and we had a selection, so clear it.
      if (mounted) {
        setState(() {
          _selectedItemGroup = null;
        });
      }
      debugPrint("[EditStockItemScreen] Groups are empty, clearing selected group.");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _propControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadPreferencesAndSetupControllers() async {
    _activeProperties = await AppPrefs.getItemProperties();
    _quantityDecimals = await AppPrefs.getQuantityDecimals();

    final initialQuantity = widget.initialItem?.quantity ?? 0.0;
    _quantityController.text = initialQuantity.toStringAsFixed(_quantityDecimals);

    if (_activeProperties.contains(AppPrefs.propCategory)) {
      _categoryController.text = widget.initialItem?.properties[AppPrefs.propCategory]?.toString() ?? "";
    }
    
    _propControllers[AppPrefs.propDescription]?.text = widget.initialItem?.properties[AppPrefs.propDescription]?.toString() ?? "";
    _propControllers[AppPrefs.propBarcode]?.text = widget.initialItem?.properties[AppPrefs.propBarcode]?.toString() ?? "";
    _propControllers[AppPrefs.propUom]?.text = widget.initialItem?.properties[AppPrefs.propUom]?.toString() ?? "";

    _setupDynamicControllers(); 

    if (mounted) setState(() {}); 
  }

  void _setupDynamicControllers() {
    final Map<String, TextEditingController> newPropControllers = {};

    final explicitlyHandledKeys = {
      AppPrefs.propName, 
      AppPrefs.propQuantity, 
      AppPrefs.propImage, 
      AppPrefs.propGroupId, 
      AppPrefs.propCategory, 
      AppPrefs.propDescription, 
      AppPrefs.propBarcode, 
      AppPrefs.propUom, 
    };

    for (String propKey in _activeProperties) {
      if (!explicitlyHandledKeys.contains(propKey)) {
        String initialValue = widget.initialItem?.properties[propKey]?.toString() ?? "";
        // Reuse existing controller if available, otherwise create new
        newPropControllers[propKey] = _propControllers[propKey] ?? TextEditingController(text: initialValue);
        // Ensure text is set if controller was reused but empty
        if (newPropControllers[propKey]!.text.isEmpty && initialValue.isNotEmpty) {
           newPropControllers[propKey]!.text = initialValue;
        }
      }
    }

    // Dispose controllers that are no longer active or needed (excluding dedicated ones)
    List<String> keysToDispose = [];
    _propControllers.forEach((key, controller) {
      if (!newPropControllers.containsKey(key) && 
          key != AppPrefs.propDescription && 
          key != AppPrefs.propBarcode && 
          key != AppPrefs.propUom) {
        keysToDispose.add(key);
      }
    });
    for (var key in keysToDispose) {
      _propControllers[key]?.dispose();
      _propControllers.remove(key);
    }
    
    // Add new controllers to _propControllers, preserving dedicated ones
    newPropControllers.forEach((key, controller) {
        _propControllers[key] = controller;
    });
  }

  bool _ensureApiServiceToken() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (mounted) _showErrorSnackbar("Sessão inválida. Faça login novamente.");
      return false;
    }
    _apiService.setAuthToken(token);
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source, 
        imageQuality: 80, 
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile != null && mounted) {
        setState(() { 
          _selectedImageFile = File(pickedFile.path); 
          _currentImageUrl = null; 
        });
        _showInfoSnackbar("Imagem selecionada com sucesso!");
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar("Erro ao selecionar imagem: $e");
    }
  }

  /// Permite selecionar qualquer arquivo (e não só imagem)
  Future<void> _pickAnyFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        final path = result.files.single.path;
        if (path != null) {
          setState(() {
            _selectedImageFile = File(path);
            _currentImageUrl = null;
          });
          _showInfoSnackbar("Arquivo selecionado: ${result.files.single.name}");
        }
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Erro ao selecionar arquivo: $e');
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    if (!_activeProperties.contains(AppPrefs.propImage)) {
      _showInfoSnackbar("Gerenciamento de imagens desativado.");
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Selecionar Imagem',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_camera, color: Colors.blue),
                ),
                title: const Text("Câmera"),
                subtitle: const Text("Tirar uma foto"),
                onTap: () { 
                  Navigator.of(ctx).pop(); 
                  _pickImage(ImageSource.camera); 
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.green),
                ),
                title: const Text("Galeria"),
                subtitle: const Text("Escolher da galeria de fotos"),
                onTap: () { 
                  Navigator.of(ctx).pop(); 
                  _pickImage(ImageSource.gallery); 
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_file, color: Colors.orange),
                ),
                title: const Text("Arquivo"),
                subtitle: const Text("Escolher qualquer arquivo"),
                onTap: () { 
                  Navigator.of(ctx).pop(); 
                  _pickAnyFile(); 
                },
              ),
              if (_selectedImageFile != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty))
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text("Remover Imagem", style: TextStyle(color: Colors.red)),
                  subtitle: const Text("Excluir imagem atual"),
                  onTap: () {
                    if (mounted) {
                      setState(() { 
                        _selectedImageFile = null; 
                        _currentImageUrl = null; 
                      });
                      Navigator.of(ctx).pop();
                      _showInfoSnackbar("Imagem removida. Salve para confirmar.");
                    }
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  Future<void> _saveItem() async {
    FocusScope.of(context).unfocus();
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate() || _isLoading) {
      return;
    }
    if (!_ensureApiServiceToken()) {
      _showErrorSnackbar("Erro: Usuário não autenticado.");
      return;
    }

    setState(() => _isLoading = true);

    final normalizedQuantity = _quantityController.text.replaceAll(",", ".");
    final double quantity = double.tryParse(normalizedQuantity) ?? 0.0;

    final Map<String, dynamic> properties = {};

    if (_activeProperties.contains(AppPrefs.propCategory)) {
      final categoryValue = _categoryController.text.trim();
      properties[AppPrefs.propCategory] = categoryValue.isNotEmpty ? categoryValue : null;
    }

    final dedicatedPropKeys = [AppPrefs.propDescription, AppPrefs.propBarcode, AppPrefs.propUom];
    for (var key in dedicatedPropKeys) {
      if (_activeProperties.contains(key) && _propControllers.containsKey(key)) {
        final value = _propControllers[key]!.text.trim();
        properties[key] = value.isNotEmpty ? value : null;
      } else if (_activeProperties.contains(key)) {
         properties[key] = null; 
      }
    }
    
    _propControllers.forEach((key, controller) {
      if (_activeProperties.contains(key) && 
          !dedicatedPropKeys.contains(key) && 
          key != AppPrefs.propCategory) {
        final value = controller.text.trim();
        properties[key] = value.isNotEmpty ? value : null;
      }
    });

    try {
      StockItem itemToSave;
      StockItem? savedItemResult; 

      final int? groupId = _selectedItemGroup?.id;

      if (_isEditing) {
        itemToSave = widget.initialItem!.copyWith(
          name: _nameController.text.trim(),
          quantity: quantity,
          groupId: groupId, 
          properties: properties,
        );
        // ApiService methods are non-nullable, so result will not be null unless an exception occurs
        savedItemResult = await _apiService.updateStockItem(widget.storeId, itemToSave.id, itemToSave);
      } else {
        itemToSave = StockItem(
          id: 0, 
          storeId: widget.storeId,
          name: _nameController.text.trim(),
          quantity: quantity,
          groupId: groupId, 
          properties: properties,
          createdAt: DateTime.now().toIso8601String(), 
          updatedAt: DateTime.now().toIso8601String(),
        );
        // ApiService methods are non-nullable
        savedItemResult = await _apiService.createStockItem(widget.storeId, itemToSave);
      }
      
      StockItem currentSavedItem = savedItemResult; 

      bool imageOperationAttempted = false;
      String? finalImageUrl = currentSavedItem.imageUrl; 

      if (_selectedImageFile != null) {
        imageOperationAttempted = true;
        if (mounted) ErrorHandler.showLoadingSnackBar(context, "Enviando imagem...");
        try {
          // ApiService.uploadImage is non-nullable
          final StockItem itemWithImage = await _apiService.uploadImage(widget.storeId, currentSavedItem.id, _selectedImageFile!);
          if (mounted) ScaffoldMessenger.of(context).removeCurrentSnackBar();
          finalImageUrl = itemWithImage.imageUrl; 
          currentSavedItem = itemWithImage; 
          if (mounted) {
            _showInfoSnackbar("Imagem enviada com sucesso!");
            setState(() {
              _currentImageUrl = finalImageUrl;
              _selectedImageFile = null;
            });
          }
        } catch (uploadError) {
          if (mounted) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            _showErrorSnackbar("Erro ao enviar imagem: ${ErrorHandler.handleError(uploadError)}. O item foi salvo sem a nova imagem.");
          }
        }
      } else if (_isEditing && _currentImageUrl == null && (widget.initialItem?.imageUrl != null && widget.initialItem!.imageUrl!.isNotEmpty)) {
        imageOperationAttempted = true;
        if (mounted) ErrorHandler.showLoadingSnackBar(context, "Removendo imagem do servidor...");
        try {
          await _apiService.deleteItemImage(widget.storeId, currentSavedItem.id);
          finalImageUrl = null; 
          if (mounted) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            _showInfoSnackbar("Imagem removida no servidor.");
            setState(() {
              _currentImageUrl = null; 
            });
          }
        } catch (imgError) {
          if (mounted) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            _showErrorSnackbar("Erro ao remover imagem no servidor: ${ErrorHandler.handleError(imgError)}");
          }
        }
      }

      final StockItem resultItemToReturn = currentSavedItem.copyWith(imageUrl: finalImageUrl);

      if (mounted) {
        if (imageOperationAttempted) {
            await Future.delayed(Duration(milliseconds: (_selectedImageFile == null && finalImageUrl == null) ? 500 : 1500));
        }
        Navigator.pop(context, resultItemToReturn); 
      }

    } catch (e) {
      if (mounted) { 
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        _showErrorSnackbar("Erro ao salvar item: ${ErrorHandler.handleError(e)}"); 
      }
    } finally {
      if (mounted) { setState(() => _isLoading = false); }
    }
  }

  Future<void> _deleteItem() async {
    if (!_isEditing || _isLoading) return;
    if (!_ensureApiServiceToken()) { _showErrorSnackbar("Erro: Usuário não autenticado."); return; }

    final bool confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: Text("Tem certeza que deseja excluir o item \"${widget.initialItem!.name}\"? Esta ação não pode ser desfeita."),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancelar")),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Excluir"),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmed && mounted) {
      setState(() => _isLoading = true);
      ErrorHandler.showLoadingSnackBar(context, "Excluindo item...");
      try {
        await _apiService.deleteStockItem(widget.storeId, widget.initialItem!.id);
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        if (mounted) {
          Navigator.pop(context, true); // Sinaliza sucesso
        }
      } catch (e) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        if (mounted) {
          _showErrorSnackbar("Erro ao excluir item: $e");
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ErrorHandler.showErrorSnackBar(context, message);
  }

  void _showInfoSnackbar(String message) {
    if (!mounted) return;
    ErrorHandler.showSuccessSnackBar(context, message);
  }

  /// Navega para a página de scanner e obtém o código lido
  Future<void> _scanBarcode() async {
    if (!_activeProperties.contains(AppPrefs.propBarcode)) {
      _showInfoSnackbar('Leitura de código de barras desativada.');
      return;
    }
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (result != null && mounted) {
      setState(() {
        _propControllers[AppPrefs.propBarcode]?.text = result;
      });
    }
  }

  /// Gera um código de barras aleatório de 13 dígitos
  void _generateBarcode() {
    final random = Random.secure();
    final code = List.generate(13, (_) => random.nextInt(10)).join();
    setState(() {
      _propControllers[AppPrefs.propBarcode]?.text = code;
    });
  }

  // Helper para obter a imagem (local ou remota)
  ImageProvider? _getImageProvider() {
    if (_selectedImageFile != null) {
      return FileImage(_selectedImageFile!);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      Map<String, String>? headers;
      if (token != null) {
        headers = {"Authorization": "Bearer $token"};
      }
      // Add a cache-busting query parameter to force reload if URL is the same but content changed
      return NetworkImage("$_currentImageUrl?v=${DateTime.now().millisecondsSinceEpoch}", headers: headers);
    }
    return null;
  }

  Widget _buildImageActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupSelectionDialog() {
    final itemGroupProvider = Provider.of<ItemGroupProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecionar Grupo'),
          content: SizedBox(
            width: double.maxFinite,
            child: itemGroupProvider.groups.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Nenhum grupo disponível.'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: itemGroupProvider.groups.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          title: const Text('Sem grupo'),
                          onTap: () {
                            setState(() {
                              _selectedItemGroup = null;
                            });
                            Navigator.of(context).pop();
                          },
                          trailing: _selectedItemGroup == null 
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                        );
                      }
                      
                      final group = itemGroupProvider.groups[index - 1];
                      return ListTile(
                        title: Text(group.name),
                        subtitle: group.description?.isNotEmpty == true 
                            ? Text(group.description!)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedItemGroup = group;
                          });
                          Navigator.of(context).pop();
                        },
                        trailing: _selectedItemGroup?.id == group.id
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemGroupProvider = context.watch<ItemGroupProvider>();

    // Schedule state updates for after the build completes to avoid navigator lock
    if (_isEditing && widget.initialItem?.groupId != null && itemGroupProvider.groups.isNotEmpty) {
      bool needsUpdate = _selectedItemGroup == null || _selectedItemGroup!.id != widget.initialItem!.groupId;
      if (needsUpdate) {
          final groupExists = itemGroupProvider.groups.any((g) => g.id == widget.initialItem!.groupId);
          if (groupExists) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _updateSelectedItemGroupFromProvider();
              }
            });
          } else { // Group does not exist in provider
             if (_selectedItemGroup != null) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedItemGroup != null && !itemGroupProvider.groups.any((g) => g.id == widget.initialItem!.groupId)) {
                      setState(() {
                          _selectedItemGroup = null;
                      });
                  }
              });
             }
          }
      }
    } else if (_isEditing && widget.initialItem?.groupId != null && _selectedItemGroup != null && itemGroupProvider.groups.isEmpty && !itemGroupProvider.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedItemGroup != null && itemGroupProvider.groups.isEmpty && !itemGroupProvider.isLoading) {
                setState(() {
                    _selectedItemGroup = null;
                });
            }
        });
    }

    if (_activeProperties.isEmpty && !_isLoading) {
      return Scaffold(
          appBar: AppBar(title: Text(_isEditing ? "Editar Item" : "Adicionar Item")),
          body: const Center(child: CircularProgressIndicator()));
    }

    // Start of UI refactoring based on user prompt
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isLoading) return; // Prevent pop if loading
            // Use a safe navigation method that doesn't interfere with build cycles
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(_isEditing ? "Editar Item" : "Adicionar Item"),
        actions: [
          IconButton(
            icon: const Icon(Icons.label_outline), // Etiqueta (categorias)
            tooltip: 'Categorias/Grupos',
            onPressed: () {
              _showGroupSelectionDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: "Salvar",
            onPressed: _isLoading ? null : _saveItem,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteItem();
              }
              // Adicionar mais opções se necessário
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (_isEditing)
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Excluir Item', style: TextStyle(color: Colors.red)),
                ),
              // Outras opções podem ser adicionadas aqui
            ],
          ),
        ],
      ),
      body: Stack( // Stack for loading overlay
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Seletor de Loja
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    alignment: Alignment.center,
                    child: Consumer<StoreProvider>(
                      builder: (context, storeProvider, child) {
                        final stores = storeProvider.stores;
                        final selectedStore = storeProvider.selectedStore;
                        
                        if (stores.isEmpty) {
                          return const Text(
                            "Nenhuma loja disponível",
                            style: TextStyle(color: Colors.grey),
                          );
                        }
                        
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: selectedStore?.id,
                            isDense: true,
                            hint: const Text("Selecione uma loja"),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text("– Todas as Lojas –"),
                              ),
                              ...stores.map((store) => DropdownMenuItem(
                                value: store.id,
                                child: Text(store.name),
                              )),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                storeProvider.selectAllStores();
                              } else {
                                final store = stores.firstWhere((s) => s.id == value);
                                storeProvider.selectStore(store);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo Nome do Item
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration( // Added const
                      labelText: 'Nome do Item',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => (value?.trim().isEmpty ?? true) ? 'Nome é obrigatório' : null,
                  ),
                  const SizedBox(height: 16),

                  // Campo Código de Barras
                  TextFormField(
                    controller: _propControllers[AppPrefs.propBarcode],
                    decoration: InputDecoration(
                      labelText: 'Código de Barras',
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min, // Importante para Row dentro de suffixIcon
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Gerar código',
                            onPressed: _generateBarcode,
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt),
                            tooltip: 'Escanear código',
                            onPressed: _scanBarcode,
                          ),
                        ],
                      ),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),

                  // Campo Descrição
                  TextFormField(
                    controller: _propControllers[AppPrefs.propDescription],
                    decoration: const InputDecoration( // Added const
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3, // Permitir até 3-4 linhas
                  ),
                  const SizedBox(height: 16),

                  // Campo Quantidade
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Quantidade:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            border: InputBorder.none, // Para um visual mais limpo
                            contentPadding: EdgeInsets.symmetric(vertical: 0)
                          ),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                          ],
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) return 'Quantidade é obrigatória';
                            final normalizedValue = value!.trim().replaceAll(',', '.');
                            final parsedValue = double.tryParse(normalizedValue);
                            if (parsedValue == null) return 'Quantidade inválida';
                            if (parsedValue < 0) return 'Quantidade não pode ser negativa';
                            return null;
                          },
                        ),
                      ),
                      FloatingActionButton.small(
                        heroTag: 'increment_quantity',
                        onPressed: () {
                          double currentValue = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0.0;
                          setState(() {
                            _quantityController.text = (currentValue + 1).toStringAsFixed(_quantityDecimals);
                          });
                        },
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: 'decrement_quantity',
                        onPressed: () {
                          double currentValue = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0.0;
                          if (currentValue > 0) {
                            setState(() {
                              _quantityController.text = (currentValue - 1).toStringAsFixed(_quantityDecimals);
                            });
                          }
                        },
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Divider(),
                  const Center(child: Icon(Icons.keyboard_arrow_down)),
                  const SizedBox(height: 16),

                  // Área de Imagens (Placeholder 1)
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, style: BorderStyle.solid, width: 1), // Alterado para sólido
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Adicionar da Galeria'),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Capturar com Câmera'),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Área de Miniaturas (Placeholder 2)
                  // Esta área será dinâmica baseada em _selectedImageFile e _currentImageUrl
                  _buildImagePreviewSection(),
                  const SizedBox(height: 16),


                  // --- Seleção de Grupo ---
                  if (_activeProperties.contains(AppPrefs.propGroupId))
                    Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: DropdownButtonFormField<ItemGroup>(
                          value: _selectedItemGroup,
                          decoration: const InputDecoration(
                            labelText: 'Grupo do Item',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.category_outlined, color: Colors.orange),
                          ),
                          items: [
                            const DropdownMenuItem<ItemGroup>(
                              value: null,
                              child: Text('Sem grupo'),
                            ),
                            ...itemGroupProvider.groups.map((group) =>
                              DropdownMenuItem<ItemGroup>(
                                value: group,
                                child: Text(group.name),
                              ),
                            ),
                          ],
                          onChanged: (ItemGroup? newGroup) {
                            if (mounted) {
                              setState(() {
                                _selectedItemGroup = newGroup;
                              });
                            }
                          },
                          isExpanded: true,
                        ),
                      ),
                    ),
                  
                  // --- Categoria (Texto Livre) ---
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Categoria (texto livre)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bookmark_border_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 70), // Espaço para o botão flutuante não cobrir
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      // FloatingActionButton removido para seguir o novo design (botão check na AppBar)
    );
  }

  Widget _buildImagePreviewSection() {
    final imageProvider = _getImageProvider();
    return Container(
      height: 120, // Altura para miniaturas
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey, style: BorderStyle.solid, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[100],
      ),
      child: imageProvider != null
          ? Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                    height: 100,
                    width: 100,
                    errorBuilder: (context, error, stackTrace) => 
                      const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                  ),
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                    tooltip: 'Remover Imagem',
                    onPressed: _isLoading ? null : () {
                      if (mounted) {
                        setState(() {
                          _selectedImageFile = null;
                          _currentImageUrl = null;
                        });
                        _showInfoSnackbar("Imagem removida. Salve para confirmar a remoção no servidor.");
                      }
                    },
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_search, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma imagem selecionada',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
    );
  }
}
