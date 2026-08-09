import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/documents_repository.dart';
import '../domain/document_models.dart';

final Provider<DocumentsRepository> documentsRepositoryProvider =
    Provider<DocumentsRepository>(
      (Ref ref) => DocumentsRepository(ref.watch(apiClientProvider)),
    );

/// `GET /documents/types`.
final AutoDisposeFutureProvider<List<DocumentType>> documentTypesProvider =
    FutureProvider.autoDispose<List<DocumentType>>(
      (Ref ref) => ref.watch(documentsRepositoryProvider).fetchTypes(),
    );

/// `GET /documents/project/{project_id}`, cacheado por proyecto.
final AutoDisposeFutureProviderFamily<List<ProjectDocument>, String>
projectDocumentsProvider = FutureProvider.autoDispose
    .family<List<ProjectDocument>, String>(
      (Ref ref, String projectId) =>
          ref.watch(documentsRepositoryProvider).fetchByProject(projectId),
    );

/// `GET /documents/versions/{document_id}`.
final AutoDisposeFutureProviderFamily<List<DocumentVersion>, String>
documentVersionsProvider = FutureProvider.autoDispose
    .family<List<DocumentVersion>, String>(
      (Ref ref, String documentId) =>
          ref.watch(documentsRepositoryProvider).fetchVersions(documentId),
    );
