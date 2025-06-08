// frontend/lib/core/presentation/providers/improved_document_provider.dart
import 'package:flutter/widgets.dart';
import '../../data/models/document_model.dart';
import '../../data/datasources/api_service.dart';

enum DocumentProviderState {
  idle,
  loading,
  loaded,
  error,
  saving,
  saved,
}

class ImprovedDocumentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
    // State management
  DocumentProviderState _state = DocumentProviderState.idle;
  int? _storeId;
  final List<DocumentModel> _documents = [];
  DocumentModel? _currentDocument;
  String? _errorMessage;
  
  // Getters
  DocumentProviderState get state => _state;
  List<DocumentModel> get documents => List.unmodifiable(_documents);
  DocumentModel? get currentDocument => _currentDocument;
  String? get error => _errorMessage;
  bool get isLoading => _state == DocumentProviderState.loading;
  bool get isSaving => _state == DocumentProviderState.saving;
  bool get hasError => _state == DocumentProviderState.error;

  ImprovedDocumentProvider() {
    debugPrint("ImprovedDocumentProvider inicializado.");
  }

  // Update authentication token
  void updateAuthToken(String? token) {
    _apiService.setAuthToken(token);
    debugPrint("[ImprovedDocumentProvider] Token atualizado");
  }

  // Set store ID and trigger data refresh
  void setStoreId(int? storeId) {
    if (_storeId == storeId) return;
    
    _storeId = storeId;
    _clearData();
    
    if (storeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchDocuments();
      });
    }
  }

  // Clear all data
  void _clearData() {
    _documents.clear();
    _currentDocument = null;
    _errorMessage = null;
    _state = DocumentProviderState.idle;
    notifyListeners();
  }

  // Set state and notify listeners
  void _setState(DocumentProviderState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  // Set error state
  void _setError(String message) {
    _errorMessage = message;
    _setState(DocumentProviderState.error);
    debugPrint("[ImprovedDocumentProvider] Erro: $message");
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == DocumentProviderState.error) {
      _setState(DocumentProviderState.idle);
    }
  }

  /// Fetch all documents for the current store
  Future<void> fetchDocuments({bool forceRefresh = false}) async {
    if (_storeId == null) {
      _setError('ID da loja não definido');
      return;
    }

    if (_state == DocumentProviderState.loading) {
      return; // Already loading
    }

    if (!forceRefresh && _documents.isNotEmpty && _state == DocumentProviderState.loaded) {
      return; // Already loaded and not forcing refresh
    }

    try {
      _setState(DocumentProviderState.loading);
      clearError();

      final documents = await _apiService.fetchDocuments(_storeId!);
      
      _documents.clear();
      _documents.addAll(documents);
      
      _setState(DocumentProviderState.loaded);
      
      debugPrint("[ImprovedDocumentProvider] ${_documents.length} documentos carregados para store ID: $_storeId");
      
      // Debug: log each document
      for (var doc in _documents) {
        debugPrint("[ImprovedDocumentProvider] Document: ID=${doc.id}, Number=${doc.number}, Type=${doc.type}");
      }
    } catch (e) {
      _setError('Erro ao carregar documentos: $e');
    }
  }

  /// Fetch specific document by ID
  Future<DocumentModel?> fetchDocumentById(int documentId) async {
    if (_storeId == null) {
      _setError('ID da loja não definido');
      return null;
    }

    try {
      final document = await _apiService.fetchDocumentById(_storeId!, documentId);
      _currentDocument = document;
      
      debugPrint("[ImprovedDocumentProvider] Documento $documentId carregado");
      return document;
    } catch (e) {
      _setError('Erro ao carregar documento: $e');
      return null;
    }
  }

  /// Create new document
  Future<DocumentModel?> createDocument(DocumentModel document) async {
    if (_storeId == null) {
      _setError('ID da loja não definido');
      return null;
    }

    try {
      _setState(DocumentProviderState.saving);
      clearError();

      final newDocument = await _apiService.createDocument(_storeId!, document);
      
      // Add to local list
      _documents.insert(0, newDocument); // Add at beginning for newest first
      _currentDocument = newDocument;
      
      _setState(DocumentProviderState.saved);
      
      debugPrint("[ImprovedDocumentProvider] Documento criado: ${newDocument.id}");
      
      // Automatically switch back to loaded state after a brief moment
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_state == DocumentProviderState.saved) {
          _setState(DocumentProviderState.loaded);
        }
      });
      
      return newDocument;
    } catch (e) {
      _setError('Erro ao criar documento: $e');
      return null;
    }
  }

  /// Update existing document
  Future<DocumentModel?> updateDocument(int documentId, DocumentModel document) async {
    if (_storeId == null) {
      _setError('ID da loja não definido');
      return null;
    }

    try {
      _setState(DocumentProviderState.saving);
      clearError();

      final updatedDocument = await _apiService.updateDocumentHeader(_storeId!, documentId, document);
      
      // Update in local list
      final index = _documents.indexWhere((d) => d.id == documentId);
      if (index != -1) {
        _documents[index] = updatedDocument;
      }
      _currentDocument = updatedDocument;
      
      _setState(DocumentProviderState.saved);
      
      debugPrint("[ImprovedDocumentProvider] Documento atualizado: $documentId");
      
      // Automatically switch back to loaded state after a brief moment
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_state == DocumentProviderState.saved) {
          _setState(DocumentProviderState.loaded);
        }
      });
      
      return updatedDocument;
    } catch (e) {
      _setError('Erro ao atualizar documento: $e');
      return null;
    }
  }

  /// Delete document
  Future<bool> deleteDocument(int documentId) async {
    if (_storeId == null) {
      _setError('ID da loja não definido');
      return false;
    }

    try {
      _setState(DocumentProviderState.saving);
      clearError();

      await _apiService.deleteDocument(_storeId!, documentId);
      
      // Remove from local list
      _documents.removeWhere((d) => d.id == documentId);
      
      if (_currentDocument?.id == documentId) {
        _currentDocument = null;
      }
      
      _setState(DocumentProviderState.loaded);
      
      debugPrint("[ImprovedDocumentProvider] Documento deletado: $documentId");
      return true;
    } catch (e) {
      _setError('Erro ao deletar documento: $e');
      return false;
    }
  }
  /// Process document (change status to processed)
  Future<DocumentModel?> processDocument(int documentId) async {
    if (_storeId == null) {
      _setError('ID da loja não definido');
      return null;
    }

    try {
      _setState(DocumentProviderState.saving);
      clearError();

      // API service processDocument returns void, so we call it and then fetch the updated document
      await _apiService.processDocument(_storeId!, documentId);
      
      // Update status in local list (since API doesn't return the updated document)
      final index = _documents.indexWhere((d) => d.id == documentId);
      if (index != -1) {
        final updatedDocument = _documents[index].copyWith(status: 'PROCESSADO');
        _documents[index] = updatedDocument;
        _currentDocument = updatedDocument;
        
        _setState(DocumentProviderState.saved);
        
        debugPrint("[ImprovedDocumentProvider] Documento processado: $documentId");
        
        // Automatically switch back to loaded state after a brief moment
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_state == DocumentProviderState.saved) {
            _setState(DocumentProviderState.loaded);
          }
        });
        
        return updatedDocument;
      }
      
      _setState(DocumentProviderState.loaded);
      return null;
    } catch (e) {
      _setError('Erro ao processar documento: $e');
      return null;
    }
  }
  /// Cancel document
  Future<DocumentModel?> cancelDocument(int documentId) async {
    if (_storeId == null) {
      _setError('ID da loja não definido');
      return null;
    }

    try {
      _setState(DocumentProviderState.saving);
      clearError();

      // API service cancelDocument returns void, so we call it and then update locally
      await _apiService.cancelDocument(_storeId!, documentId);
      
      // Update status in local list (since API doesn't return the updated document)
      final index = _documents.indexWhere((d) => d.id == documentId);
      if (index != -1) {
        final cancelledDocument = _documents[index].copyWith(status: 'CANCELADO');
        _documents[index] = cancelledDocument;
        _currentDocument = cancelledDocument;
        
        _setState(DocumentProviderState.saved);
        
        debugPrint("[ImprovedDocumentProvider] Documento cancelado: $documentId");
        
        // Automatically switch back to loaded state after a brief moment
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_state == DocumentProviderState.saved) {
            _setState(DocumentProviderState.loaded);
          }
        });
        
        return cancelledDocument;
      }
      
      _setState(DocumentProviderState.loaded);
      return null;
    } catch (e) {
      _setError('Erro ao cancelar documento: $e');
      return null;
    }
  }

  /// Filter documents by type
  List<DocumentModel> getDocumentsByType(String type) {
    return _documents.where((doc) => doc.type.toLowerCase() == type.toLowerCase()).toList();
  }

  /// Filter documents by status
  List<DocumentModel> getDocumentsByStatus(String status) {
    return _documents.where((doc) => doc.status.toLowerCase() == status.toLowerCase()).toList();
  }

  /// Filter documents by date range
  List<DocumentModel> getDocumentsByDateRange(DateTime startDate, DateTime endDate) {
    return _documents.where((doc) {
      try {
        final docDate = DateTime.parse(doc.date);
        return docDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               docDate.isBefore(endDate.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Search documents by number or description
  List<DocumentModel> searchDocuments(String query) {
    if (query.isEmpty) return _documents;
    
    final lowerQuery = query.toLowerCase();
    return _documents.where((doc) {
      return doc.number.toLowerCase().contains(lowerQuery) ||
             doc.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get total value of all documents
  double getTotalValue() {
    return _documents.fold(0.0, (sum, doc) => sum + doc.totalValue);
  }

  /// Get total value by type
  double getTotalValueByType(String type) {
    return getDocumentsByType(type).fold(0.0, (sum, doc) => sum + doc.totalValue);
  }

  /// Refresh data (force reload from server)
  Future<void> refresh() async {
    await fetchDocuments(forceRefresh: true);
  }
}
