import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/site_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import '../../schedule/application/schedule_providers.dart';
import '../../schedule/domain/schedule_task.dart';
import '../application/photos_providers.dart';
import '../domain/project_photo.dart';
import 'photo_detail_sheet.dart';

/// Fotos de obra (`GET /photos/{project_id}`), alojadas en Supabase Storage.
class PhotosScreen extends ConsumerWidget {
  const PhotosScreen({super.key});

  static const String routeName = 'photos';
  static const String routePath = '/photos';

  @override
  Widget build(BuildContext context, WidgetRef ref) => ModuleScaffold(
    title: 'Fotos',
    currentPath: routePath,
    onRefresh: () => ref.invalidate(projectPhotosProvider),
    body: ProjectScope(
      emptyMessage: ref.watch(stringsProvider).photos.needsProject,
      builder: (BuildContext context, Project project) =>
          _PhotosGrid(project: project),
    ),
  );
}

class _PhotosGrid extends ConsumerWidget {
  const _PhotosGrid({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProjectPhoto>> photos = ref.watch(
      projectPhotosProvider(project.id),
    );
    final PhotosStrings strings = ref.watch(stringsProvider).photos;

    // Mapa id → nombre de las tareas del cronograma, para rotular cada foto.
    final Map<String, String> taskNames = <String, String>{
      for (final ScheduleTask task
          in ref.watch(projectScheduleProvider(project.id)).valueOrNull ??
              const <ScheduleTask>[])
        task.id: task.name,
    };

    return AsyncSection<List<ProjectPhoto>>(
      value: photos,
      errorMessage: strings.loadError,
      onRetry: () => ref.invalidate(projectPhotosProvider(project.id)),
      builder: (List<ProjectPhoto> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.photo_camera_rounded,
              title: strings.emptyTitle,
              message: strings.emptyFor(project.name),
            )
          : RefreshIndicator(
              color: AppColors.orangeNeon,
              backgroundColor: AppColors.surface,
              onRefresh: () async =>
                  ref.invalidate(projectPhotosProvider(project.id)),
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 190,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 180,
                ),
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) => _PhotoTile(
                  photo: data[index],
                  taskName: taskNames[data[index].taskId],
                ),
              ),
            ),
    );
  }
}

class _PhotoTile extends ConsumerWidget {
  const _PhotoTile({required this.photo, this.taskName});

  final ProjectPhoto photo;

  /// Nombre de la tarea asociada, si la foto trae `task_id` y la tarea existe.
  final String? taskName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    final AppStrings strings = ref.watch(stringsProvider);
    final bool canDelete = user?.can(Perm.photosDelete) ?? false;

    // `InkWell` envolviendo toda la celda: el toque abre el detalle desde
    // cualquier punto de la foto, sin competencia con textos ni botones.
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showPhotoDetailSheet(context, photo: photo),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // `cacheWidth` decodifica la imagen al tamaño de la celda en vez de
            // a resolución completa: una foto de móvil ocuparía ~48 MB.
            Image.network(
              photo.photoUrl,
              fit: BoxFit.cover,
              cacheWidth: 380,
              filterQuality: FilterQuality.low,
              loadingBuilder:
                  (
                    BuildContext context,
                    Widget child,
                    ImageChunkEvent? progress,
                  ) => progress == null
                  ? child
                  : const ColoredBox(
                      color: AppColors.surface,
                      child: Center(
                        child: SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? _) =>
                      const ColoredBox(
                        color: AppColors.surface,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ),
            ),
            // Degradado inferior para que el texto se lea sobre cualquier foto.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 70,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (photo.description.isNotEmpty)
                    Text(
                      photo.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  if (taskName != null && taskName!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      taskName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    Fmt.date(photo.createdAt),
                    style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            if (photo.hasLocation)
              const Positioned(
                left: 8,
                top: 8,
                child: Icon(
                  Icons.location_on_rounded,
                  size: 17,
                  color: Colors.white70,
                ),
              ),
            if (canDelete)
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  tooltip: strings.common.delete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  color: Colors.white70,
                  onPressed: () => _delete(context, ref),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final PhotosStrings strings = ref.read(stringsProvider).photos;
    final bool confirmed = await confirmDestructive(
      context,
      title: strings.deleteTitle,
      message: strings.deleteMessage,
    );
    if (!confirmed || !context.mounted) return;

    final bool ok = await runWithFeedback(
      context,
      action: () => ref.read(photosRepositoryProvider).deleteWithFile(photo),
      successMessage: strings.deleted,
    );
    if (ok) ref.invalidate(projectPhotosProvider(photo.projectId));
  }
}
