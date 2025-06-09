// lib/core/presentation/providers/document_provider.dart
import 'package:flutter/widgets.dart';
import '../../data/models/document_model.dart';
import '../../data/datasources/api_service.dart';
import '../../../shared/utils/error_handler.dart';
import 'stock_provider.dart';

class DocumentProvider with ChangeNotifier, ErrorHandlingMixin {
  final ApiService _apiService = ApiService();
  int? _storeId;
  List<DocumentModel> _documents = [];
  DocumentModel? _currentDocument;
  StockProvider? _stockProvider;

  List<DocumentModel> get documents => _documents;
  DocumentModel? get currentDocument => _currentDocument;

  DocumentProvider() {
    debugPrint("DocumentProvider inicializado.");
  }

  /// Configurar referência ao StockProvider para atualizações automáticas de estoque
  void setStockProvider(StockProvider? stockProvider) {
    _stockProvider = stockProvider;
    debugPrint("[DocumentProvider] StockProvider configurado: ${stockProvider != null ? 'presente' : 'nulo'}");
  }

  // Método para atualizar o token de autenticação
  void updateAuthToken(String? token) {
    _apiService.setAuthToken(token);
    debugPrint("[DocumentProvider] Token atualizado: ${token != null ? 'presente' : 'nulo'}");
  }

  // Método para definir o ID da loja atual
  void setStoreId(int? storeId) {
    if (_storeId == storeId) return;
    _storeId = storeId;
    _documents.clear();
    _currentDocument = null;
    clearError();
    debugPrint("[DocumentProvider] Store ID definido: $storeId");

    if (storeId != null) {
      // Use postFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchDocuments();
      });
    }
    notifyListeners();
  }

  /// Buscar todos os documentos da loja
  Future<void> fetchDocuments() async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'fetchDocuments');
      return;
    }

    await handleAsyncOperation(() async {
      _documents = await _apiService.fetchDocuments(_storeId!);
      debugPrint("[DocumentProvider] ${_documents.length} documentos carregados para store ID: $_storeId");
      
      // Debug: log each document
      for (var doc in _documents) {
        debugPrint("[DocumentProvider] Document: ID=${doc.id}, Number=${doc.number}, Type=${doc.type}, Date=${doc.date}");
      }
    }, 'fetchDocuments');
  }

  /// Buscar documento específico por ID
  Future<DocumentModel?> fetchDocumentById(int documentId) async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'fetchDocumentById');
      return null;
    }

    return await handleAsyncOperation(() async {
      final document = await _apiService.fetchDocumentById(_storeId!, documentId);
      _currentDocument = document;
      debugPrint("[DocumentProvider] Documento $documentId carregado");
      return document;
    }, 'fetchDocumentById');
  }

  /// Criar novo documento
  Future<DocumentModel?> createDocument(DocumentModel document) async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'createDocument');
      return null;
    }

    return await handleAsyncOperation(() async {
      final newDocument = await _apiService.createDocument(_storeId!, document);
      _documents.add(newDocument);
      _currentDocument = newDocument;
      
      // Aplicar mudanças no estoque automaticamente se StockProvider estiver disponível
      if (_stockProvider != null && newDocument.items.isNotEmpty) {
        _stockProvider!.applyDocumentStockChanges(newDocument.items, newDocument.type);
        debugPrint("[DocumentProvider] Estoque atualizado automaticamente para documento ${newDocument.id} (${newDocument.type})");
      }
      
      debugPrint("[DocumentProvider] Documento criado: ${newDocument.id}");
      return newDocument;
    }, 'createDocument');
  }

  /// Cancelar documento
  Future<void> cancelDocument(int documentId) async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'cancelDocument');
      return;
    }

    await handleAsyncOperation(() async {
      // Buscar o documento antes de cancelar para ter acesso aos itens
      DocumentModel? documentToCancel;
      final index = _documents.indexWhere((d) => d.id?.toString() == documentId.toString());
      if (index != -1) {
        documentToCancel = _documents[index];
      } else if (_currentDocument?.id?.toString() == documentId.toString()) {
        documentToCancel = _currentDocument;
      }

      await _apiService.cancelDocument(_storeId!, documentId);
      
      // Remove the document from the local list since backend now deletes it
      if (index != -1) {
        _documents.removeAt(index);
      }
      
      // Clear current document if it was the one cancelled
      if (_currentDocument?.id?.toString() == documentId.toString()) {
        _currentDocument = null;
      }
      
      // Reverter mudanças no estoque se StockProvider estiver disponível e documento tiver itens
      if (_stockProvider != null && documentToCancel != null && documentToCancel.items.isNotEmpty) {
        _stockProvider!.revertDocumentStockChanges(documentToCancel.items, documentToCancel.type);
        debugPrint("[DocumentProvider] Estoque revertido automaticamente para documento cancelado $documentId (${documentToCancel.type})");
      }
      
      debugPrint("[DocumentProvider] Documento $documentId cancelado");
    }, 'cancelDocument');
  }

  /// Buscar documentos com filtros
  Future<void> fetchDocumentsWithFilters(Map<String, dynamic> filters) async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'fetchDocumentsWithFilters');
      return;
    }

    await handleAsyncOperation(() async {
      _documents = await _apiService.fetchDocumentsWithFilters(_storeId!, filters);
      debugPrint("[DocumentProvider] ${_documents.length} documentos carregados com filtros");
    }, 'fetchDocumentsWithFilters');
  }
  /// Deletar documento
  Future<void> deleteDocument(int documentId) async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'deleteDocument');
      return;
    }

    await handleAsyncOperation(() async {
      await _apiService.deleteDocument(_storeId!, documentId);
      
      // Remover da lista local
      _documents.removeWhere((d) => d.id?.toString() == documentId.toString());
      
      if (_currentDocument?.id?.toString() == documentId.toString()) {
        _currentDocument = null;
      }
      
      debugPrint("[DocumentProvider] Documento $documentId deletado");
    }, 'deleteDocument');
  }

  /// Limpar documento atual
  void clearCurrentDocument() {
    if (_currentDocument != null) {
      _currentDocument = null;
      notifyListeners();
    }
  }
  /// Buscar documentos por tipo (ex: 'entrada', 'saida')
  List<DocumentModel> getDocumentsByType(String type) {
    return _documents.where((doc) => doc.type == type).toList();
  }

  // Removed getDocumentsByStatus method since status field no longer exists

  /// Buscar documentos por período
  List<DocumentModel> getDocumentsByDateRange(DateTime start, DateTime end) {
    return _documents.where((doc) {
      try {
        final docDate = DateTime.parse(doc.date);
        return docDate.isAfter(start.subtract(const Duration(days: 1))) &&
               docDate.isBefore(end.add(const Duration(days: 1)));
      } catch (e) {
        debugPrint("Erro ao analisar data do documento ${doc.id}: ${doc.date}");
        return false;
      }
    }).toList();
  }

  /// Limpar todos os dados (útil para logout)
  void clearAll() {
    _documents.clear();
    _currentDocument = null;
    _storeId = null;
    clearError();
    notifyListeners();
    debugPrint("[DocumentProvider] Todos os dados limpos");
  }
}
