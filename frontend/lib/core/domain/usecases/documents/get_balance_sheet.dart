// Get Balance Sheet Use Case - Clean Architecture
import '../../entities/balance_sheet_entity.dart';
import '../../entities/document_entity.dart';
import '../../repositories/document_repository.dart';

class GetBalanceSheetUseCase {
  final DocumentRepository _documentRepository;

  const GetBalanceSheetUseCase(this._documentRepository);

  Future<BalanceSheetEntity> call({
    required int storeId,
    required BalanceSheetPeriodEntity period,
  }) async {
    try {
      // Get documents for the specified period
      final documents = await _documentRepository.getDocumentsInDateRange(
        storeId,
        period.startDate,
        period.endDate,
      );

      // Filter documents based on the period
      final filteredDocuments = documents.where((doc) {
        return period.contains(doc.date);
      }).toList();

      // Calculate balance sheet from filtered documents
      return BalanceSheetEntity.fromDocuments(filteredDocuments);
    } catch (e) {
      throw BalanceSheetException('Failed to calculate balance sheet: $e');
    }
  }

  /// Calculate balance sheet from a list of documents
  BalanceSheetEntity calculateFromDocuments(List<DocumentEntity> documents) {
    return BalanceSheetEntity.fromDocuments(documents);
  }

  /// Filter documents by period
  List<DocumentEntity> filterDocumentsByPeriod(
    List<DocumentEntity> documents,
    BalanceSheetPeriodEntity period,
  ) {
    return documents.where((doc) {
      return period.contains(doc.date);
    }).toList();
  }
}

class BalanceSheetException implements Exception {
  final String message;
  const BalanceSheetException(this.message);

  @override
  String toString() => 'BalanceSheetException: $message';
}
