import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/presentation/providers/improved_document_provider.dart';

void main() {
  group('Improved Document Integration Tests', () {    testWidgets('ImprovedDocumentProvider can be instantiated', (WidgetTester tester) async {
      expect(() => ImprovedDocumentProvider(), returnsNormally);
    });

    test('ImprovedDocumentProvider initial state', () {
      final provider = ImprovedDocumentProvider();
      
      expect(provider.state, DocumentProviderState.idle);
      expect(provider.documents, isEmpty);
      expect(provider.currentDocument, isNull);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.isSaving, isFalse);
    });
  });
}