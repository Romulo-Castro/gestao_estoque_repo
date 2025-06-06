// lib/providers/document_provider.dart
import 'package:flutter/foundation.dart';
import '/models/document_model.dart';
import '/services/api_service.dart';
import '/utils/error_handler.dart';

class DocumentProvider with ChangeNotifier, ErrorHandlingMixin {
  final ApiService _apiService = ApiService();
  int? _storeId;
  List<Document> _documents = [];
  Document? _currentDocument;

  List<Document> get documents => _documents;
  Document? get currentDocument => _currentDocument;

  DocumentProvider() {
    debugPrint("DocumentProvider inicializado.");
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
    notifyListeners();
    debugPrint("[DocumentProvider] Store ID definido: $storeId");

    if (storeId != null) {
      fetchDocuments();
    }
  }

  /// Buscar todos os documentos da loja
  Future<void> fetchDocuments() async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'fetchDocuments');
      return;
    }

    await handleAsyncOperation(() async {
      _documents = await _apiService.fetchDocuments(_storeId!);
      debugPrint("[DocumentProvider] ${_documents.length} documentos carregados");
    }, 'fetchDocuments');
  }

  /// Buscar documento específico por ID
  Future<Document?> fetchDocumentById(int documentId) async {
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
  Future<Document?> createDocument(Document document) async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'createDocument');
      return null;
    }

    return await handleAsyncOperation(() async {
      final newDocument = await _apiService.createDocument(_storeId!, document);
      _documents.add(newDocument);
      _currentDocument = newDocument;
      debugPrint("[DocumentProvider] Documento criado: ${newDocument.id}");
      return newDocument;
    }, 'createDocument');
  }

  /// Atualizar cabeçalho do documento
  Future<Document?> updateDocumentHeader(int documentId, Document document) async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'updateDocumentHeader');
      return null;
    }

    return await handleAsyncOperation(() async {
      final updatedDocument = await _apiService.updateDocumentHeader(
        _storeId!, 
        documentId, 
        document
      );
        // Atualizar na lista local
      final index = _documents.indexWhere((d) => d.id == documentId.toString());
      if (index != -1) {
        _documents[index] = updatedDocument;
      }
      
      if (_currentDocument?.id == documentId.toString()) {
        _currentDocument = updatedDocument;
      }
      
      debugPrint("[DocumentProvider] Documento $documentId atualizado");
      return updatedDocument;
    }, 'updateDocumentHeader');
  }  /// Atualizar status do documento
  Future<Document?> updateDocumentStatus(int documentId, String status) async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'updateDocumentStatus');
      return null;
    }

    return await handleAsyncOperation(() async {
      // Usar o novo método da API
      final updatedDocument = await _apiService.updateDocumentStatus(_storeId!, documentId, status);
      
      // Atualizar na lista local
      final index = _documents.indexWhere((d) => d.id == documentId.toString());
      
      if (index != -1) {
        _documents[index] = updatedDocument;
      }
      
      if (_currentDocument?.id == documentId.toString()) {
        _currentDocument = updatedDocument;
      }
      
      debugPrint("[DocumentProvider] Status do documento $documentId atualizado para: $status");
      return updatedDocument;
    }, 'updateDocumentStatus');
  }

  /// Atualizar documento completo
  Future<Document?> updateDocument(int documentId, Document document) async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'updateDocument');
      return null;
    }

    return await handleAsyncOperation(() async {
      final updatedDocument = await _apiService.updateDocument(_storeId!, documentId, document);
      
      // Atualizar na lista local
      final index = _documents.indexWhere((d) => d.id == documentId.toString());
      if (index != -1) {
        _documents[index] = updatedDocument;
      }
      
      if (_currentDocument?.id == documentId.toString()) {
        _currentDocument = updatedDocument;
      }
      
      debugPrint("[DocumentProvider] Documento $documentId atualizado");
      return updatedDocument;
    }, 'updateDocument');
  }

  /// Cancelar documento
  Future<void> cancelDocument(int documentId) async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'cancelDocument');
      return;
    }

    await handleAsyncOperation(() async {
      await _apiService.cancelDocument(_storeId!, documentId);
      
      // Atualizar na lista local
      final index = _documents.indexWhere((d) => d.id == documentId.toString());
      if (index != -1) {
        _documents[index] = _documents[index].copyWith(status: 'CANCELADO');
      }
      
      if (_currentDocument?.id == documentId.toString()) {
        _currentDocument = _currentDocument!.copyWith(status: 'CANCELADO');
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
      _documents.removeWhere((d) => d.id == documentId.toString());
      
      if (_currentDocument?.id == documentId.toString()) {
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
  List<Document> getDocumentsByType(String type) {
    final documentType = stringToDocumentType(type);
    return _documents.where((doc) => doc.type == documentType).toList();
  }

  /// Buscar documentos por status
  List<Document> getDocumentsByStatus(String status) {
    return _documents.where((doc) => doc.status == status).toList();
  }
  /// Buscar documentos por período
  List<Document> getDocumentsByDateRange(DateTime start, DateTime end) {
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
