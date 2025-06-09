// Domain entity for Balance Sheet - Clean Architecture
import 'package:equatable/equatable.dart';
import 'document_entity.dart';

class BalanceSheetEntity extends Equatable {
  final double totalInflows;
  final double totalOutflows;
  final double netBalance;
  final int inflowCount;
  final int outflowCount;
  final List<BalanceSheetItemEntity> inflowItems;
  final List<BalanceSheetItemEntity> outflowItems;
  final DateTime periodStart;
  final DateTime periodEnd;

  const BalanceSheetEntity({
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

  @override
  List<Object?> get props => [
        totalInflows,
        totalOutflows,
        netBalance,
        inflowCount,
        outflowCount,
        inflowItems,
        outflowItems,
        periodStart,
        periodEnd,
      ];

  factory BalanceSheetEntity.fromDocuments(List<DocumentEntity> documents) {
    final inflowItems = <BalanceSheetItemEntity>[];
    final outflowItems = <BalanceSheetItemEntity>[];
    
    double totalInflows = 0.0;
    double totalOutflows = 0.0;
    
    DateTime? earliestDate;
    DateTime? latestDate;

    for (final document in documents) {
      // Removed isCancelled check since status field no longer exists
      
      // Update date range
      if (earliestDate == null || document.date.isBefore(earliestDate)) {
        earliestDate = document.date;
      }
      if (latestDate == null || document.date.isAfter(latestDate)) {
        latestDate = document.date;
      }
      
      final item = BalanceSheetItemEntity(
        documentNumber: document.number,
        description: document.description,
        date: document.date,
        value: document.totalValue,
        type: document.type,
      );
      
      if (document.isInflow) {
        inflowItems.add(item);
        totalInflows += document.totalValue;
      } else if (document.isOutflow) {
        outflowItems.add(item);
        totalOutflows += document.totalValue;
      }
    }
    
    // Set default date range if no documents
    final periodStart = earliestDate ?? DateTime.now();
    final periodEnd = latestDate ?? DateTime.now();
    
    return BalanceSheetEntity(
      totalInflows: totalInflows,
      totalOutflows: totalOutflows,
      netBalance: totalInflows - totalOutflows,
      inflowCount: inflowItems.length,
      outflowCount: outflowItems.length,
      inflowItems: inflowItems,
      outflowItems: outflowItems,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  bool get hasPositiveBalance => netBalance > 0;
  bool get hasNegativeBalance => netBalance < 0;
  bool get isBalanced => netBalance == 0;
}

class BalanceSheetItemEntity extends Equatable {
  final String documentNumber;
  final String description;
  final DateTime date;
  final double value;
  final DocumentType type;

  const BalanceSheetItemEntity({
    required this.documentNumber,
    required this.description,
    required this.date,
    required this.value,
    required this.type,
  });

  @override
  List<Object?> get props => [
        documentNumber,
        description,
        date,
        value,
        type,
      ];
}

enum BalanceSheetPeriodType { today, thisWeek, thisMonth, custom, all }

class BalanceSheetPeriodEntity extends Equatable {
  final BalanceSheetPeriodType type;
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  const BalanceSheetPeriodEntity({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  @override
  List<Object?> get props => [type, startDate, endDate, label];

  bool contains(DateTime date) {
    return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
           date.isBefore(endDate.add(const Duration(days: 1)));
  }

  factory BalanceSheetPeriodEntity.today() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return BalanceSheetPeriodEntity(
      type: BalanceSheetPeriodType.today,
      startDate: today,
      endDate: today.add(const Duration(days: 1)),
      label: 'Hoje',
    );
  }

  factory BalanceSheetPeriodEntity.thisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return BalanceSheetPeriodEntity(
      type: BalanceSheetPeriodType.thisWeek,
      startDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
      endDate: DateTime(weekEnd.year, weekEnd.month, weekEnd.day),
      label: 'Esta Semana',
    );
  }

  factory BalanceSheetPeriodEntity.thisMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    return BalanceSheetPeriodEntity(
      type: BalanceSheetPeriodType.thisMonth,
      startDate: monthStart,
      endDate: monthEnd,
      label: 'Este Mês',
    );
  }

  factory BalanceSheetPeriodEntity.all() {
    final now = DateTime.now();
    return BalanceSheetPeriodEntity(
      type: BalanceSheetPeriodType.all,
      startDate: DateTime(2000),
      endDate: DateTime(now.year + 10),
      label: 'Todos os Períodos',
    );
  }

  factory BalanceSheetPeriodEntity.custom(DateTime start, DateTime end) {
    return BalanceSheetPeriodEntity(
      type: BalanceSheetPeriodType.custom,
      startDate: start,
      endDate: end,
      label: 'Período Personalizado',
    );
  }
}
