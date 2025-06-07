// Dependency Injection Setup - Clean Architecture
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';

// Domain
import '../core/domain/repositories/document_repository.dart';
import '../core/domain/usecases/documents/get_documents.dart';
import '../core/domain/usecases/documents/get_balance_sheet.dart';

// Data
import '../core/data/datasources/remote/document_remote_datasource.dart';
import '../core/data/repositories/document_repository_impl.dart';

// Presentation
import '../core/presentation/providers/clean_document_provider.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // External dependencies
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  // Data sources
  getIt.registerLazySingleton<DocumentRemoteDataSource>(
    () => DocumentRemoteDataSourceImpl(
      httpClient: getIt(),
      baseUrl: 'http://localhost:3000', // TODO: Move to config
    ),
  );

  // Repositories
  getIt.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(
      remoteDataSource: getIt(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<GetDocumentsUseCase>(
    () => GetDocumentsUseCase(getIt()),
  );

  getIt.registerLazySingleton<GetBalanceSheetUseCase>(
    () => GetBalanceSheetUseCase(getIt()),
  );

  // Providers
  getIt.registerFactory<CleanDocumentProvider>(
    () => CleanDocumentProvider(
      getDocumentsUseCase: getIt(),
      getBalanceSheetUseCase: getIt(),
    ),
  );
}

// Helper function to reset dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
  await initializeDependencies();
}
