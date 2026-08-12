import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/queries.dart';
import '../data/progress_repository.dart';
import '../domain/daily_report.dart';

final Provider<ProgressRepository> progressRepositoryProvider =
    Provider<ProgressRepository>(
      (Ref ref) => ProgressRepository(ref.watch(apiClientProvider)),
    );

/// Día del reporte que se está consultando —o levantando—.
///
/// Vive aquí y no en la pantalla porque el formulario también lo mueve: al
/// guardar un parte con otra fecha, la pantalla salta a ese día.
final StateProvider<DateTime> progressDayProvider = StateProvider<DateTime>(
  (Ref ref) => DateTime.now(),
);

/// `GET /progress/{project_id}?date=…`. `null` = sin reporte ese día.
///
/// La clave se construye con [projectDateQuery].
final AutoDisposeFutureProviderFamily<DailyReport?, ProjectDateQuery>
dailyReportProvider = FutureProvider.autoDispose
    .family<DailyReport?, ProjectDateQuery>(
      (Ref ref, ProjectDateQuery query) => ref
          .watch(progressRepositoryProvider)
          .fetchByDate(query.projectId, query.date),
    );
