// frontend/lib/core/presentation/providers/refactored_document_provider.dart
import 'package:flutter/widgets.dart';
import '../../data/models/document_model.dart';
import '../../data/datasources/api_service.dart';
import '../../../shared/utils/error_handler.dart';

class RefactoredDocumentProvider with ChangeNotifier, ErrorHandlingMixin {
  final ApiService _apiService = ApiService();
  
  int? _storeId;
  List<DocumentModel> _documents = [];
  DocumentModel? _currentDocument;
  bool _isLoading = false;
  bool _isSaving = false;
  // Getters
  List<DocumentModel> get documents => List.unmodifiable(_documents);
  DocumentModel? get currentDocument => _currentDocument;
  @override
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  int? get storeId => _storeId;

  RefactoredDocumentProvider() {
    debugPrint("[RefactoredDocumentProvider] Inicializado");
  }

  /// Update authentication token
  void updateAuthToken(String? token) {
    _apiService.setAuthToken(token);
    debugPrint("[RefactoredDocumentProvider] Token atualizado: ${token != null ? 'presente' : 'nulo'}");
  }

  /// Set store ID and load documents
  void setStoreId(int? storeId) {
    if (_storeId == storeId) return;
    
    _storeId = storeId;
    _documents.clear();
    _currentDocument = null;
    clearError();
    
    debugPrint("[RefactoredDocumentProvider] Store ID definido: $storeId");
    
    if (storeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchDocuments();
      });
    }
    notifyListeners();
  }
  /// Fetch all documents for the current store
  Future<void> fetchDocuments() async {
    if (_storeId == null) {
      setError('ID da loja não definido', 'fetchDocuments');
      return;
    }

    await handleAsyncOperation(() async {
      _isLoading = true;
      notifyListeners();

      try {
        debugPrint("[RefactoredDocumentProvider] Buscando documentos para loja $_storeId");
        
        final documents = await _apiService.fetchDocuments(_storeId!);
        _documents = documents;
        
        debugPrint("[RefactoredDocumentProvider] ${_documents.length} documentos carregados");
      } catch (e) {
        debugPrint("[RefactoredDocumentProvider] Erro ao buscar documentos: $e");
        setError('Erro ao carregar documentos: $e', 'fetchDocuments');
        _documents = [];
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }, 'fetchDocuments');
  }
  /// Fetch a specific document by ID
  Future<void> fetchDocumentById(String documentId) async {
    await handleAsyncOperation(() async {
      _isLoading = true;
      notifyListeners();

      try {
        debugPrint("[RefactoredDocumentProvider] Buscando documento: $documentId");
        
        _currentDocument = await _apiService.fetchDocumentById(_storeId!, int.parse(documentId));
        debugPrint("[RefactoredDocumentProvider] Documento carregado: ${_currentDocument?.number}");
      } catch (e) {
        debugPrint("[RefactoredDocumentProvider] Erro ao buscar documento: $e");
        setError('Erro ao carregar documento: $e', 'fetchDocumentById');
        _currentDocument = null;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }, 'fetchDocumentById');
  }  /// Create a new document
  Future<DocumentModel> createDocument(DocumentModel document) async {
    final result = await handleAsyncOperation(() async {
      _isSaving = true;
      notifyListeners();

      try {
        debugPrint("[RefactoredDocumentProvider] Criando documento: ${document.number}");
        
        final createdDocument = await _apiService.createDocument(_storeId!, document);
        
        // Add to local list
        _documents.insert(0, createdDocument);
        _currentDocument = createdDocument;
        
        debugPrint("[RefactoredDocumentProvider] Documento criado com ID: ${createdDocument.id}");
        
        return createdDocument;
      } catch (e) {
        debugPrint("[RefactoredDocumentProvider] Erro ao criar documento: $e");
        setError('Erro ao criar documento: $e', 'createDocument');
        rethrow;
      } finally {
        _isSaving = false;
        notifyListeners();
      }
    }, 'createDocument');
    
    if (result == null) {
      throw Exception('Falha ao criar documento');
    }
    
    return result;
  }  /// Update an existing document
  Future<DocumentModel> updateDocument(DocumentModel document) async {
    final result = await handleAsyncOperation(() async {
      _isSaving = true;
      notifyListeners();

      try {
        debugPrint("[RefactoredDocumentProvider] Atualizando documento: ${document.id}");
        
        final updatedDocument = await _apiService.updateDocument(_storeId!, document.id!, document);
        
        // Update in local list
        final index = _documents.indexWhere((doc) => doc.id == updatedDocument.id);
        if (index != -1) {
          _documents[index] = updatedDocument;
        }
        
        _currentDocument = updatedDocument;
        
        debugPrint("[RefactoredDocumentProvider] Documento atualizado: ${updatedDocument.number}");
        
        return updatedDocument;
      } catch (e) {
        debugPrint("[RefactoredDocumentProvider] Erro ao atualizar documento: $e");
        setError('Erro ao atualizar documento: $e', 'updateDocument');
        rethrow;
      } finally {
        _isSaving = false;
        notifyListeners();
      }
    }, 'updateDocument');
    
    if (result == null) {
      throw Exception('Falha ao atualizar documento');
    }
    
    return result;
  }
  /// Delete a document
  Future<void> deleteDocument(int documentId) async {
    await handleAsyncOperation(() async {
      try {
        debugPrint("[RefactoredDocumentProvider] Deletando documento: $documentId");
        
        await _apiService.deleteDocument(_storeId!, documentId);
        
        // Remove from local list
        _documents.removeWhere((doc) => doc.id == documentId);
        
        // Clear current document if it was deleted
        if (_currentDocument?.id == documentId) {
          _currentDocument = null;
        }
        
        debugPrint("[RefactoredDocumentProvider] Documento deletado com sucesso");
      } catch (e) {
        debugPrint("[RefactoredDocumentProvider] Erro ao deletar documento: $e");
        setError('Erro ao deletar documento: $e', 'deleteDocument');
        rethrow;
      } finally {
        notifyListeners();
      }
    }, 'deleteDocument');
  }  /// Search documents by criteria
  Future<List<DocumentModel>> searchDocuments({
    String? query,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await handleAsyncOperation(() async {
      try {
        debugPrint("[RefactoredDocumentProvider] Pesquisando documentos");
        
        final filters = <String, dynamic>{};
        if (query != null && query.isNotEmpty) filters['q'] = query;
        if (type != null && type.isNotEmpty) filters['type'] = type;
        if (startDate != null) filters['start_date'] = startDate.toIso8601String();
        if (endDate != null) filters['end_date'] = endDate.toIso8601String();
        
        final documents = await _apiService.fetchDocumentsWithFilters(_storeId!, filters);
        
        return documents;
      } catch (e) {
        debugPrint("[RefactoredDocumentProvider] Erro na pesquisa: $e");
        setError('Erro na pesquisa: $e', 'searchDocuments');
        return <DocumentModel>[];
      }
    }, 'searchDocuments');
    
    return result ?? <DocumentModel>[];
  }

  /// Get documents by type
  List<DocumentModel> getDocumentsByType(String type) {
    return _documents.where((doc) => doc.type.toLowerCase() == type.toLowerCase()).toList();
  }

  /// Get documents by date range
  List<DocumentModel> getDocumentsByDateRange(DateTime start, DateTime end) {
    return _documents.where((doc) {
      try {
        final docDate = DateTime.parse(doc.date);
        return docDate.isAfter(start.subtract(const Duration(days: 1))) &&
               docDate.isBefore(end.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Calculate total value by type
  double getTotalValueByType(String type) {
    return getDocumentsByType(type)
        .fold<double>(0, (sum, doc) => sum + doc.totalValue);
  }

  /// Get document statistics
  Map<String, dynamic> getDocumentStatistics() {
    final entradas = getDocumentsByType('entrada');
    final saidas = getDocumentsByType('saida');
    
    return {
      'total_documents': _documents.length,
      'total_entradas': entradas.length,
      'total_saidas': saidas.length,
      'value_entradas': entradas.fold<double>(0, (sum, doc) => sum + doc.totalValue),
      'value_saidas': saidas.fold<double>(0, (sum, doc) => sum + doc.totalValue),
      'last_document': _documents.isNotEmpty ? _documents.first : null,
    };
  }

  /// Clear current document
  void clearCurrentDocument() {
    _currentDocument = null;
    notifyListeners();
  }

  /// Refresh documents
  Future<void> refresh() async {
    await fetchDocuments();
  }

  /// Check if document number is unique
  bool isDocumentNumberUnique(String number, {int? excludeId}) {
    return !_documents.any((doc) => 
        doc.number.toLowerCase() == number.toLowerCase() && 
        doc.id != excludeId);
  }

  /// Get next document number suggestion
  String getNextDocumentNumber(String type) {
    final typeDocuments = getDocumentsByType(type);
    final prefix = type == 'entrada' ? 'ENT' : 'SAI';
    
    if (typeDocuments.isEmpty) {
      return '$prefix-001';
    }
    
    int maxNumber = 0;
    for (final doc in typeDocuments) {
      final match = RegExp(r'(\d+)$').firstMatch(doc.number);
      if (match != null) {
        final number = int.tryParse(match.group(1)!) ?? 0;
        if (number > maxNumber) {
          maxNumber = number;
        }
      }
    }
    
    return '$prefix-${(maxNumber + 1).toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _documents.clear();
    _currentDocument = null;
    super.dispose();
  }
}
