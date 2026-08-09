import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../data/photos_repository.dart';
import '../domain/project_photo.dart';

final Provider<PhotosRepository> photosRepositoryProvider =
    Provider<PhotosRepository>((Ref ref) {
      final PhotosRepository repository = PhotosRepository(
        ref.watch(apiClientProvider),
      );
      ref.onDispose(repository.close);
      return repository;
    });

/// `GET /photos/{project_id}`, cacheado por proyecto.
final AutoDisposeFutureProviderFamily<List<ProjectPhoto>, String>
projectPhotosProvider = FutureProvider.autoDispose
    .family<List<ProjectPhoto>, String>(
      (Ref ref, String projectId) =>
          ref.watch(photosRepositoryProvider).fetchByProject(projectId),
    );

/// `true` si el `.env` trae `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
///
/// La UI lo usa para desactivar el botón de subir en vez de dejar que falle
/// la petición.
final Provider<bool> canUploadPhotosProvider = Provider<bool>(
  (Ref ref) => AppConfig.hasSupabase,
);
