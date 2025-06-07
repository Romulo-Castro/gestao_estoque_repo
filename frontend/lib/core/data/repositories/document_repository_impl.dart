// Document Repository Implementation - Clean Architecture
import '../../domain/entities/document_entity.dart';
import '../../domain/entities/balance_sheet_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/remote/document_remote_datasource.dart';
import '../models/document_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource _remoteDataSource;

  const DocumentRepositoryImpl({
    required DocumentRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<DocumentEntity>> getDocuments(int storeId) async {
    try {
      final models = await _remoteDataSource.getDocuments(storeId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DocumentRepositoryException('Failed to fetch documents: $e');
    }
  }

  @override
  Future<DocumentEntity?> getDocumentById(int documentId) async {
    try {
      final model = await _remoteDataSource.getDocumentById(documentId);
      return model?.toEntity();
    } catch (e) {
      throw DocumentRepositoryException('Failed to fetch document: $e');
    }
  }

  @override
  Future<DocumentEntity> createDocument(DocumentEntity document) async {
    try {
      final model = DocumentModel.fromEntity(document);
      final createdModel = await _remoteDataSource.createDocument(model);
      return createdModel.toEntity();
    } catch (e) {
      throw DocumentRepositoryException('Failed to create document: $e');
    }
  }

  @override
  Future<DocumentEntity> updateDocument(DocumentEntity document) async {
    try {
      final model = DocumentModel.fromEntity(document);
      final updatedModel = await _remoteDataSource.updateDocument(model);
      return updatedModel.toEntity();
    } catch (e) {
      throw DocumentRepositoryException('Failed to update document: $e');
    }
  }

  @override
  Future<void> deleteDocument(int documentId) async {
    try {
      await _remoteDataSource.deleteDocument(documentId);
    } catch (e) {
      throw DocumentRepositoryException('Failed to delete document: $e');
    }
  }

  @override
  Future<List<DocumentEntity>> getDocumentsByType(int storeId, DocumentType type) async {
    try {
      final typeString = _documentTypeToString(type);
      final models = await _remoteDataSource.getDocumentsByType(storeId, typeString);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DocumentRepositoryException('Failed to fetch documents by type: $e');
    }
  }

  @override
  Future<List<DocumentEntity>> getDocumentsInDateRange(
    int storeId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final models = await _remoteDataSource.getDocumentsInDateRange(
        storeId, 
        startDate, 
        endDate
      );
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DocumentRepositoryException('Failed to fetch documents in date range: $e');
    }
  }

  @override
  Future<BalanceSheetEntity> getBalanceSheet(
    int storeId, 
    BalanceSheetPeriodEntity period
  ) async {
    try {
      final documents = await getDocumentsInDateRange(
        storeId,
        period.startDate,
        period.endDate,
      );

      // Filter documents by period and active status
      final filteredDocuments = documents.where((doc) {
        return period.contains(doc.date) && !doc.isCancelled;
      }).toList();

      return BalanceSheetEntity.fromDocuments(filteredDocuments);
    } catch (e) {
      throw DocumentRepositoryException('Failed to calculate balance sheet: $e');
    }
  }

  @override
  Future<List<DocumentEntity>> searchDocuments(int storeId, String query) async {
    try {
      final models = await _remoteDataSource.searchDocuments(storeId, query);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DocumentRepositoryException('Failed to search documents: $e');
    }
  }

  @override
  Future<DocumentStatistics> getDocumentStatistics(int storeId) async {
    try {
      final documents = await getDocuments(storeId);
      
      final activeDocuments = documents.where((doc) => !doc.isCancelled).toList();
      final inflows = activeDocuments.where((doc) => doc.isInflow).toList();
      final outflows = activeDocuments.where((doc) => doc.isOutflow).toList();
      
      final totalInflowValue = inflows.fold<double>(
        0.0, 
        (sum, doc) => sum + doc.totalValue
      );
      
      final totalOutflowValue = outflows.fold<double>(
        0.0, 
        (sum, doc) => sum + doc.totalValue
      );

      return DocumentStatistics(
        totalDocuments: activeDocuments.length,
        totalInflows: inflows.length,
        totalOutflows: outflows.length,
        totalInflowValue: totalInflowValue,
        totalOutflowValue: totalOutflowValue,
        netValue: totalInflowValue - totalOutflowValue,
      );
    } catch (e) {
      throw DocumentRepositoryException('Failed to calculate statistics: $e');
    }
  }

  String _documentTypeToString(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return 'entrada';
      case DocumentType.saida:
        return 'saida';
      case DocumentType.unknown:
        return 'unknown';
    }
  }
}

class DocumentRepositoryException implements Exception {
  final String message;
  const DocumentRepositoryException(this.message);

  @override
  String toString() => 'DocumentRepositoryException: $message';
}
