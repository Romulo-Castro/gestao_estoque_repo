// Get Documents Use Case - Clean Architecture
import '../../entities/document_entity.dart';
import '../../repositories/document_repository.dart';

class GetDocumentsUseCase {
  final DocumentRepository _documentRepository;

  const GetDocumentsUseCase(this._documentRepository);

  Future<List<DocumentEntity>> call(int storeId) async {
    try {
      return await _documentRepository.getDocuments(storeId);
    } catch (e) {
      throw DocumentException('Failed to fetch documents: $e');
    }
  }

  Future<List<DocumentEntity>> getByType(int storeId, DocumentType type) async {
    try {
      return await _documentRepository.getDocumentsByType(storeId, type);
    } catch (e) {
      throw DocumentException('Failed to fetch documents by type: $e');
    }
  }

  Future<List<DocumentEntity>> searchDocuments(int storeId, String query) async {
    try {
      return await _documentRepository.searchDocuments(storeId, query);
    } catch (e) {
      throw DocumentException('Failed to search documents: $e');
    }
  }

  Future<List<DocumentEntity>> getInDateRange(
    int storeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _documentRepository.getDocumentsInDateRange(
        storeId,
        startDate,
        endDate,
      );
    } catch (e) {
      throw DocumentException('Failed to fetch documents in date range: $e');
    }
  }
}

class DocumentException implements Exception {
  final String message;
  const DocumentException(this.message);

  @override
  String toString() => 'DocumentException: $message';
}
