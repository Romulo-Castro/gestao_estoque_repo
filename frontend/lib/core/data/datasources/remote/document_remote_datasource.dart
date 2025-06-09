// Document Remote Data Source - Clean Architecture
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/document_model.dart';

abstract class DocumentRemoteDataSource {
  Future<List<DocumentModel>> getDocuments(int storeId);
  Future<DocumentModel?> getDocumentById(int documentId);
  Future<DocumentModel> createDocument(DocumentModel document);
  Future<void> deleteDocument(int documentId);
  Future<List<DocumentModel>> getDocumentsByType(int storeId, String type);
  Future<List<DocumentModel>> getDocumentsInDateRange(
    int storeId, 
    DateTime startDate, 
    DateTime endDate
  );
  Future<List<DocumentModel>> searchDocuments(int storeId, String query);
}

class DocumentRemoteDataSourceImpl implements DocumentRemoteDataSource {
  final http.Client httpClient;
  final String baseUrl;

  const DocumentRemoteDataSourceImpl({
    required this.httpClient,
    required this.baseUrl,
  });

  @override
  Future<List<DocumentModel>> getDocuments(int storeId) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/api/documents?store_id=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DocumentModel.fromJson(json)).toList();
      } else {
        throw DocumentRemoteException(
          'Failed to load documents: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is DocumentRemoteException) rethrow;
      throw DocumentRemoteException('Network error: $e');
    }
  }

  @override
  Future<DocumentModel?> getDocumentById(int documentId) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/api/documents/$documentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return DocumentModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw DocumentRemoteException(
          'Failed to load document: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is DocumentRemoteException) rethrow;
      throw DocumentRemoteException('Network error: $e');
    }
  }

  @override
  Future<DocumentModel> createDocument(DocumentModel document) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/documents'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(document.toJson()),
      );

      if (response.statusCode == 201) {
        return DocumentModel.fromJson(json.decode(response.body));
      } else {
        throw DocumentRemoteException(
          'Failed to create document: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is DocumentRemoteException) rethrow;
      throw DocumentRemoteException('Network error: $e');
    }
  }

  @override
  Future<void> deleteDocument(int documentId) async {
    try {
      final response = await httpClient.delete(
        Uri.parse('$baseUrl/api/documents/$documentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DocumentRemoteException(
          'Failed to delete document: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is DocumentRemoteException) rethrow;
      throw DocumentRemoteException('Network error: $e');
    }
  }

  @override
  Future<List<DocumentModel>> getDocumentsByType(int storeId, String type) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/api/documents?store_id=$storeId&type=$type'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DocumentModel.fromJson(json)).toList();
      } else {
        throw DocumentRemoteException(
          'Failed to load documents by type: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is DocumentRemoteException) rethrow;
      throw DocumentRemoteException('Network error: $e');
    }
  }

  @override
  Future<List<DocumentModel>> getDocumentsInDateRange(
    int storeId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final start = startDate.toIso8601String();
      final end = endDate.toIso8601String();
      final response = await httpClient.get(
        Uri.parse('$baseUrl/api/documents?store_id=$storeId&start_date=$start&end_date=$end'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DocumentModel.fromJson(json)).toList();
      } else {
        throw DocumentRemoteException(
          'Failed to load documents in date range: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is DocumentRemoteException) rethrow;
      throw DocumentRemoteException('Network error: $e');
    }
  }

  @override
  Future<List<DocumentModel>> searchDocuments(int storeId, String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await httpClient.get(
        Uri.parse('$baseUrl/api/documents/search?store_id=$storeId&q=$encodedQuery'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DocumentModel.fromJson(json)).toList();
      } else {
        throw DocumentRemoteException(
          'Failed to search documents: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is DocumentRemoteException) rethrow;
      throw DocumentRemoteException('Network error: $e');
    }
  }
}

class DocumentRemoteException implements Exception {
  final String message;
  const DocumentRemoteException(this.message);

  @override
  String toString() => 'DocumentRemoteException: $message';
}
