import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/queries.dart';
import '../data/progress_repository.dart';
import '../domain/daily_report.dart';

final Provider<ProgressRepository> progressRepositoryProvider =
    Provider<ProgressRepository>(
      (Ref ref) => ProgressRepository(ref.watch(apiClientProvider)),
    );

/// `GET /progress/{project_id}?date=…`. `null` = sin reporte ese día.
///
/// La clave se construye con [projectDateQuery].
final AutoDisposeFutureProviderFamily<DailyReport?, ProjectDateQuery>
dailyReportProvider =
    FutureProvider.autoDispose.family<DailyReport?, ProjectDateQuery>(
      (Ref ref, ProjectDateQuery query) => ref
          .watch(progressRepositoryProvider)
          .fetchByDate(query.projectId, query.date),
    );
