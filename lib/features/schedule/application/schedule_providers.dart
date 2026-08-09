import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_task.dart';

final Provider<ScheduleRepository> scheduleRepositoryProvider =
    Provider<ScheduleRepository>(
      (Ref ref) => ScheduleRepository(ref.watch(apiClientProvider)),
    );

/// `GET /schedule/{project_id}`, cacheado por proyecto.
final AutoDisposeFutureProviderFamily<List<ScheduleTask>, String>
projectScheduleProvider = FutureProvider.autoDispose
    .family<List<ScheduleTask>, String>(
      (Ref ref, String projectId) =>
          ref.watch(scheduleRepositoryProvider).fetchByProject(projectId),
    );
