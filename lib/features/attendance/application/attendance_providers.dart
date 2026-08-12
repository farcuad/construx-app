import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/queries.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_models.dart';

final Provider<AttendanceRepository> attendanceRepositoryProvider =
    Provider<AttendanceRepository>(
      (Ref ref) => AttendanceRepository(ref.watch(apiClientProvider)),
    );

/// Día del que se consulta —y para el que se pasa— la lista.
///
/// Vive aquí y no en la pantalla porque el formulario también lo mueve: al
/// guardar una lista con otra fecha, la pantalla salta a ese día para que el
/// supervisor vea lo que acaba de registrar.
final StateProvider<DateTime> attendanceDayProvider = StateProvider<DateTime>(
  (Ref ref) => DateTime.now(),
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
