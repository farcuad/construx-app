import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/audits_repository.dart';
import '../domain/audit_log.dart';

final Provider<AuditsRepository> auditsRepositoryProvider =
    Provider<AuditsRepository>(
      (Ref ref) => AuditsRepository(ref.watch(apiClientProvider)),
    );

/// `GET /audits-logs`.
final AutoDisposeFutureProvider<List<AuditLog>> auditLogsProvider =
    FutureProvider.autoDispose<List<AuditLog>>(
      (Ref ref) => ref.watch(auditsRepositoryProvider).fetchAll(),
    );
