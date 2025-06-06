// lib/models/import_result.dart
class ImportResult {
  final int totalRows;
  final int successCount;
  final int errorCount;
  final List<String> errors;
  final List<String> warnings;

  ImportResult({
    required this.totalRows,
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errorCount > 0;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isSuccessful => errorCount == 0;
}

class ImportMerchandiseData {
  final String name;
  final double quantity;
  final String? barcode;
  final String? category;
  final String? description;
  final double? costPrice;
  final double? salePrice;
  final String? unit;
  final String? supplier;
  final String? location;
  final String? notes;

  ImportMerchandiseData({
    required this.name,
    required this.quantity,
    this.barcode,
    this.category,
    this.description,
    this.costPrice,
    this.salePrice,
    this.unit,
    this.supplier,
    this.location,
    this.notes,
  });

  Map<String, dynamic> toStockItemProperties() {
    return {
      'barcode': barcode,
      'category': category,
      'description': description,
      'costPrice': costPrice?.toString(),
      'salePrice': salePrice?.toString(),
      'unit': unit ?? 'UN',
      'supplier': supplier,
      'location': location,
      'notes': notes,
    };
  }
}
