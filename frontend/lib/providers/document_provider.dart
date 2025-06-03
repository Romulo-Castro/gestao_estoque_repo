// lib/providers/document_provider.dart
import 'package:flutter/foundation.dart';
import '/models/document_model.dart';
import '/services/api_service.dart';

class DocumentProvider with ChangeNotifier {
  final ApiService _apiService;
  String? _authToken;
  int? _storeId;
  List<Document> _documents = [];
  bool _isLoading = false;
  String? _error;

  DocumentProvider(this._apiService, this._authToken, List<Document>? initialDocuments) {
    if (initialDocuments != null) {
      _documents = initialDocuments;
    }
  }

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateAuthToken(String? token) {
    _authToken = token;
    _apiService.setAuthToken(token);
  }

  void setStoreId(int? storeId) {
    _storeId = storeId;
  }

  Future<void> fetchDocuments() async {
    if (_authToken == null) {
      _error = 'Não autorizado';
      notifyListeners();
      return;
    }

    if (_storeId == null) {
      _error = 'Nenhuma loja selecionada';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchDocuments(_storeId!);
      _documents = response;
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar documentos: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Document?> fetchDocumentById(String id) async {
    if (_authToken == null) {
      _error = 'Não autorizado';
      notifyListeners();
      return null;
    }

    if (_storeId == null) {
      _error = 'Nenhuma loja selecionada';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final document = await _apiService.fetchDocumentById(_storeId!, int.parse(id));
      _error = null;
      return document;
    } catch (e) {
      _error = 'Erro ao carregar documento: ${e.toString()}';
      debugPrint(_error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDocument(Document document) async {
    if (_authToken == null) {
      _error = 'Não autorizado';
      notifyListeners();
      return false;
    }

    if (_storeId == null) {
      _error = 'Nenhuma loja selecionada';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newDocument = await _apiService.createDocument(_storeId!, document);
      _documents.add(newDocument);
      _error = null;
      return true;
    } catch (e) {
      _error = 'Erro ao criar documento: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDocument(Document document) async {
    if (_authToken == null) {
      _error = 'Não autorizado';
      notifyListeners();
      return false;
    }

    if (_storeId == null) {
      _error = 'Nenhuma loja selecionada';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedDocument = await _apiService.updateDocumentHeader(_storeId!, int.parse(document.id), document);
      final index = _documents.indexWhere((d) => d.id == document.id);
      if (index != -1) {
        _documents[index] = updatedDocument;
      }
      _error = null;
      return true;
    } catch (e) {
      _error = 'Erro ao atualizar documento: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDocument(String id) async {
    if (_authToken == null) {
      _error = 'Não autorizado';
      notifyListeners();
      return false;
    }

    if (_storeId == null) {
      _error = 'Nenhuma loja selecionada';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.cancelDocument(_storeId!, int.parse(id));
      _documents.removeWhere((d) => d.id == id);
      _error = null;
      return true;
    } catch (e) {
      _error = 'Erro ao excluir documento: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> processDocument(String id) async {
    if (_authToken == null) {
      _error = 'Não autorizado';
      notifyListeners();
      return false;
    }

    if (_storeId == null) {
      _error = 'Nenhuma loja selecionada';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedDocument = await _apiService.processDocument(_storeId!, int.parse(id));
      final index = _documents.indexWhere((d) => d.id == id);
      if (index != -1) {
        _documents[index] = updatedDocument;
      }
      _error = null;
      return true;
    } catch (e) {
      _error = 'Erro ao processar documento: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelDocument(String id) async {
    if (_authToken == null) {
      _error = 'Não autorizado';
      notifyListeners();
      return false;
    }

    if (_storeId == null) {
      _error = 'Nenhuma loja selecionada';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.cancelDocument(_storeId!, int.parse(id));
      _documents.removeWhere((d) => d.id == id);
      _error = null;
      return true;
    } catch (e) {
      _error = 'Erro ao cancelar documento: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Document> getDocumentsByType(DocumentType type) {
    return _documents.where((doc) => doc.type == type).toList();
  }

  List<Document> getDocumentsByStatus(String status) {
    return _documents.where((doc) => doc.status == status).toList();
  }

  List<Document> getDocumentsByDateRange(DateTime start, DateTime end) {
    return _documents.where((doc) {
      final docDate = DateTime.parse(doc.date);
      return docDate.isAfter(start) && docDate.isBefore(end);
    }).toList();
  }

  Future<void> fetchDocumentsWithFilters({
    String? type,
    String? startDate,
    String? endDate,
    int? customerId,
    int? supplierId,
  }) async {
    if (_authToken == null) {
      _error = 'Não autorizado';
      notifyListeners();
      return;
    }

    if (_storeId == null) {
      _error = 'Nenhuma loja selecionada';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchDocumentsWithFilters(
        _storeId!,
        type: type,
        startDate: startDate,
        endDate: endDate,
        customerId: customerId,
        supplierId: supplierId,
      );
      _documents = response;
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar documentos: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

