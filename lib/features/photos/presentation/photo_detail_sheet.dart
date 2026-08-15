import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/site_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../schedule/application/schedule_providers.dart';
import '../../schedule/domain/schedule_task.dart';
import '../domain/project_photo.dart';

/// Abre el detalle de [photo]: la imagen en grande junto a su descripción,
/// la tarea a la que va asociada y la ubicación si la foto trae coordenadas.
Future<void> showPhotoDetailSheet(
  BuildContext context, {
  required ProjectPhoto photo,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (BuildContext context) => _PhotoDetailSheet(photo: photo),
);

class _PhotoDetailSheet extends ConsumerWidget {
  const _PhotoDetailSheet({required this.photo});

  final ProjectPhoto photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(stringsProvider);
    final PhotosStrings photoStrings = strings.photos;

    // El nombre de la tarea viene del cronograma de la obra: la foto guarda
    // solo su `task_id`, que puede no resolver si la tarea ya no existe.
    final String? taskName =
        photo.taskId == null ? null : _taskName(ref, photo.taskId!);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SheetHeader(title: photoStrings.detailTitle, bottom: 12),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      photo.photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (
                        BuildContext context,
                        Widget child,
                        ImageChunkEvent? progress,
                      ) => progress == null
                          ? child
                          : const ColoredBox(
                              color: AppColors.surface,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
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
                  ),
                ),
                const SizedBox(height: 14),
                if (photo.description.isNotEmpty) ...<Widget>[
                  Text(
                    photo.description,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                InfoLine(
                  icon: Icons.event_rounded,
                  text: Fmt.date(photo.createdAt),
                  top: 0,
                ),
                if (taskName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: LabeledValue(
                      label: photoStrings.task,
                      value: taskName,
                    ),
                  )
                else
                  InfoLine(
                    icon: Icons.link_off_rounded,
                    text: photoStrings.taskNotFound,
                  ),
                if (photo.hasLocation)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: LabeledValue(
                      label: photoStrings.location,
                      value:
                          '${photo.latitude!.toStringAsFixed(6)}, '
                          '${photo.longitude!.toStringAsFixed(6)}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _taskName(WidgetRef ref, String taskId) {
    final List<ScheduleTask> tasks =
        ref.watch(projectScheduleProvider(photo.projectId)).valueOrNull ??
        const <ScheduleTask>[];
    for (final ScheduleTask task in tasks) {
      if (task.id == taskId) return task.name;
    }
    return null;
  }
}