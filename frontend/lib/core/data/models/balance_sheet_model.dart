// Model for balance sheet calculations
import 'document_model.dart';
import '../../domain/entities/document_entity.dart';

class BalanceSheetData {
  final double totalInflows;
  final double totalOutflows;
  final double netBalance;
  final int inflowCount;
  final int outflowCount;
  final List<BalanceSheetItem> inflowItems;
  final List<BalanceSheetItem> outflowItems;
  final DateTime periodStart;
  final DateTime periodEnd;
  const BalanceSheetData({
    required this.totalInflows,
    required this.totalOutflows,
    required this.netBalance,
    required this.inflowCount,
    required this.outflowCount,
    required this.inflowItems,
    required this.outflowItems,
    required this.periodStart,
    required this.periodEnd,
  });

  factory BalanceSheetData.empty() {
    final now = DateTime.now();
    return BalanceSheetData(
      totalInflows: 0.0,
      totalOutflows: 0.0,
      netBalance: 0.0,
      inflowCount: 0,
      outflowCount: 0,
      inflowItems: const [],
      outflowItems: const [],
      periodStart: now,
      periodEnd: now,
    );
  }

  factory BalanceSheetData.fromDocuments(List<DocumentModel> documents) {
    final inflowItems = <BalanceSheetItem>[];
    final outflowItems = <BalanceSheetItem>[];
    
    double totalInflows = 0.0;
    double totalOutflows = 0.0;
    
    DateTime? earliestDate;
    DateTime? latestDate;

    for (final document in documents) {
      if (document.status == 'CANCELADO') continue;
      
      // Parse document date
      DateTime? docDate;
      try {
        docDate = DateTime.parse(document.date);
        if (earliestDate == null || docDate.isBefore(earliestDate)) {
          earliestDate = docDate;
        }
        if (latestDate == null || docDate.isAfter(latestDate)) {
          latestDate = docDate;
        }
      } catch (e) {
        // Skip documents with invalid dates
        continue;
      }      // Calculate total value for this document
      double documentTotal = 0.0;
      for (final item in document.items) {
        documentTotal += item.totalValue;
      }final documentType = _stringToDocumentType(document.type);      final balanceItem = BalanceSheetItem(
        documentId: document.id?.toString() ?? '',
        documentNumber: document.number,
        date: docDate,
        type: documentType,
        description: _getDocumentDescription(document),
        value: documentTotal,
        itemCount: document.items.length,
      );

      // Classify as inflow or outflow
      if (_isInflowDocument(documentType)) {
        inflowItems.add(balanceItem);
        totalInflows += documentTotal;
      } else if (_isOutflowDocument(documentType)) {
        outflowItems.add(balanceItem);
        totalOutflows += documentTotal;
      }
    }

    // Sort items by date (most recent first)
    inflowItems.sort((a, b) => b.date.compareTo(a.date));
    outflowItems.sort((a, b) => b.date.compareTo(a.date));

    return BalanceSheetData(
      totalInflows: totalInflows,
      totalOutflows: totalOutflows,
      netBalance: totalInflows - totalOutflows,
      inflowCount: inflowItems.length,
      outflowCount: outflowItems.length,
      inflowItems: inflowItems,
      outflowItems: outflowItems,
      periodStart: earliestDate ?? DateTime.now(),
      periodEnd: latestDate ?? DateTime.now(),
    );
  }
  static bool _isInflowDocument(DocumentType type) {
    return type == DocumentType.entrada;
  }

  static bool _isOutflowDocument(DocumentType type) {
    return type == DocumentType.saida;
  }
  static String _getDocumentDescription(DocumentModel document) {
    final documentType = _stringToDocumentType(document.type);
    final typeStr = _getDocumentTypeDisplayName(documentType);
    if (document.description.isNotEmpty) {
      return '$typeStr - ${document.description}';
    }
    return typeStr;
  }
  static String _getDocumentTypeDisplayName(DocumentType type) {
    switch (type) {
      case DocumentType.entrada:
        return 'Entrada';
      case DocumentType.saida:
        return 'Saída';
      case DocumentType.unknown:
        return 'Desconhecido';
    }
  }

  static DocumentType _stringToDocumentType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'entrada':
        return DocumentType.entrada;
      case 'saida':
        return DocumentType.saida;
      default:
        return DocumentType.unknown; // Default fallback
    }
  }
}

class BalanceSheetItem {
  final String documentId;
  final String documentNumber;
  final DateTime date;
  final DocumentType type;
  final String description;
  final double value;
  final int itemCount;

  const BalanceSheetItem({
    required this.documentId,
    required this.documentNumber,
    required this.date,
    required this.type,
    required this.description,
    required this.value,
    required this.itemCount,
  });
}

class BalanceSheetPeriod {
  final DateTime start;
  final DateTime end;
  final String displayName;

  const BalanceSheetPeriod({
    required this.start,
    required this.end,
    required this.displayName,
  });

  static BalanceSheetPeriod today() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return BalanceSheetPeriod(
      start: startOfDay,
      end: endOfDay,
      displayName: 'Hoje',
    );
  }

  static BalanceSheetPeriod thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    
    return BalanceSheetPeriod(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: endOfWeek,
      displayName: 'Esta Semana',
    );
  }

  static BalanceSheetPeriod thisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return BalanceSheetPeriod(
      start: startOfMonth,
      end: endOfMonth,
      displayName: 'Este Mês',
    );
  }

  static BalanceSheetPeriod all() {
    return BalanceSheetPeriod(
      start: DateTime(2020, 1, 1),
      end: DateTime.now().add(const Duration(days: 365)),
      displayName: 'Todos os Períodos',
    );
  }
  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(seconds: 1))) && 
           date.isBefore(end.add(const Duration(seconds: 1)));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BalanceSheetPeriod &&
        other.start == start &&
        other.end == end &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => Object.hash(start, end, displayName);
}
