// Document Repository Interface - Clean Architecture
import '../entities/document_entity.dart';
import '../entities/balance_sheet_entity.dart';

abstract class DocumentRepository {
  /// Fetch all documents for a specific store
  Future<List<DocumentEntity>> getDocuments(int storeId);
  
  /// Fetch a specific document by ID
  Future<DocumentEntity?> getDocumentById(int documentId);
  
  /// Create a new document
  Future<DocumentEntity> createDocument(DocumentEntity document);
  
  /// Delete a document
  Future<void> deleteDocument(int documentId);
  
  /// Get documents filtered by type
  Future<List<DocumentEntity>> getDocumentsByType(int storeId, DocumentType type);
  
  /// Get documents within a date range
  Future<List<DocumentEntity>> getDocumentsInDateRange(
    int storeId, 
    DateTime startDate, 
    DateTime endDate
  );
  
  /// Calculate balance sheet for a given period
  Future<BalanceSheetEntity> getBalanceSheet(
    int storeId, 
    BalanceSheetPeriodEntity period
  );
  
  /// Search documents by description or number
  Future<List<DocumentEntity>> searchDocuments(int storeId, String query);
  
  /// Get document statistics
  Future<DocumentStatistics> getDocumentStatistics(int storeId);
}

class DocumentStatistics {
  final int totalDocuments;
  final int totalInflows;
  final int totalOutflows;
  final double totalInflowValue;
  final double totalOutflowValue;
  final double netValue;

  const DocumentStatistics({
    required this.totalDocuments,
    required this.totalInflows,
    required this.totalOutflows,
    required this.totalInflowValue,
    required this.totalOutflowValue,
    required this.netValue,
  });
}
