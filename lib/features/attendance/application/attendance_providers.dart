import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/queries.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_models.dart';

final Provider<AttendanceRepository> attendanceRepositoryProvider =
    Provider<AttendanceRepository>(
      (Ref ref) => AttendanceRepository(ref.watch(apiClientProvider)),
    );

/// `GET /attendance/{project_id}?date=…`. `null` = aún no se ha pasado lista.
///
/// La clave se construye con [projectDateQuery].
final AutoDisposeFutureProviderFamily<Attendance?, ProjectDateQuery>
attendanceProvider = FutureProvider.autoDispose
    .family<Attendance?, ProjectDateQuery>(
      (Ref ref, ProjectDateQuery query) => ref
          .watch(attendanceRepositoryProvider)
          .fetchByDate(query.projectId, query.date),
    );
