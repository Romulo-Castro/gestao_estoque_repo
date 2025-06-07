// Document Provider using Clean Architecture - Flutter Provider
import 'package:flutter/foundation.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/entities/balance_sheet_entity.dart';
import '../../domain/usecases/documents/get_documents.dart';
import '../../domain/usecases/documents/get_balance_sheet.dart';

class CleanDocumentProvider extends ChangeNotifier {
  final GetDocumentsUseCase _getDocumentsUseCase;
  final GetBalanceSheetUseCase _getBalanceSheetUseCase;

  CleanDocumentProvider({
    required GetDocumentsUseCase getDocumentsUseCase,
    required GetBalanceSheetUseCase getBalanceSheetUseCase,
  })  : _getDocumentsUseCase = getDocumentsUseCase,
        _getBalanceSheetUseCase = getBalanceSheetUseCase;

  // State
  List<DocumentEntity> _documents = [];
  BalanceSheetEntity? _balanceSheet;
  int? _storeId;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<DocumentEntity> get documents => _documents;
  BalanceSheetEntity? get balanceSheet => _balanceSheet;
  int? get storeId => _storeId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  // Filtered documents by type
  List<DocumentEntity> get entradaDocuments =>
      _documents.where((doc) => doc.type == DocumentType.entrada).toList();

  List<DocumentEntity> get saidaDocuments =>
      _documents.where((doc) => doc.type == DocumentType.saida).toList();

  List<DocumentEntity> get activeDocuments =>
      _documents.where((doc) => !doc.isCancelled).toList();

  // Methods
  void setStoreId(int storeId) {
    if (_storeId != storeId) {
      _storeId = storeId;
      _clearData();
      loadDocuments();
    }
  }

  Future<void> loadDocuments() async {
    if (_storeId == null) {
      _setError('Store ID not set');
      return;
    }

    print('[CleanDocumentProvider] Loading documents for store: $_storeId');
    _setLoading(true);
    _clearError();

    try {
      final documents = await _getDocumentsUseCase(_storeId!);
      _documents = documents;
      print('[CleanDocumentProvider] Loaded ${documents.length} documents');
      
      // Log detailed document information for debugging
      for (final doc in documents) {
        print('[CleanDocumentProvider] Document: ${doc.number}, type: ${doc.type}, '
              'date: ${doc.date}, value: ${doc.totalValue}, status: ${doc.status}');
      }
      
      notifyListeners();
    } catch (e) {
      print('[CleanDocumentProvider] Error loading documents: $e');
      _setError('Failed to load documents: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> calculateBalanceSheet(BalanceSheetPeriodEntity period) async {
    if (_storeId == null) {
      _setError('Store ID not set');
      return;
    }

    print('[CleanDocumentProvider] Calculating balance sheet for period: ${period.label}');
    _setLoading(true);
    _clearError();

    try {
      final balanceSheet = await _getBalanceSheetUseCase(
        storeId: _storeId!,
        period: period,
      );
      
      _balanceSheet = balanceSheet;
      print('[CleanDocumentProvider] Balance sheet calculated - '
            'Inflows: ${balanceSheet.totalInflows}, '
            'Outflows: ${balanceSheet.totalOutflows}, '
            'Net: ${balanceSheet.netBalance}');
      
      notifyListeners();
    } catch (e) {
      print('[CleanDocumentProvider] Error calculating balance sheet: $e');
      _setError('Failed to calculate balance sheet: $e');
    } finally {
      _setLoading(false);
    }
  }

  BalanceSheetEntity calculateBalanceSheetFromDocuments(
    List<DocumentEntity> documents,
    BalanceSheetPeriodEntity period,
  ) {
    print('[CleanDocumentProvider] Calculating balance sheet from ${documents.length} documents');
    
    final filteredDocuments = documents.where((doc) {
      final isInPeriod = period.contains(doc.date);
      final isActive = !doc.isCancelled;
      print('[CleanDocumentProvider] Document ${doc.number}: period=$isInPeriod, active=$isActive');
      return isInPeriod && isActive;
    }).toList();

    print('[CleanDocumentProvider] Filtered to ${filteredDocuments.length} documents');
    
    final balanceSheet = BalanceSheetEntity.fromDocuments(filteredDocuments);
    _balanceSheet = balanceSheet;
    
    return balanceSheet;
  }

  List<DocumentEntity> getFilteredDocuments(String filter) {
    switch (filter.toUpperCase()) {
      case 'ENTRADA':
        return entradaDocuments;
      case 'SAÍDA':
      case 'SAIDA':
        return saidaDocuments;
      case 'BALANÇA':
      case 'BALANCA':
        return activeDocuments;
      case 'TODOS':
      default:
        return _documents;
    }
  }

  List<DocumentEntity> searchDocuments(String query) {
    if (query.isEmpty) return _documents;
    
    final lowercaseQuery = query.toLowerCase();
    return _documents.where((doc) {
      return doc.number.toLowerCase().contains(lowercaseQuery) ||
             doc.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  void refresh() {
    loadDocuments();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _clearData() {
    _documents = [];
    _balanceSheet = null;
    _error = null;
  }

  @override
  void dispose() {
    _clearData();
    super.dispose();
  }
}
