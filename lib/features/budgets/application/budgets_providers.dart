import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/budgets_repository.dart';
import '../domain/budget.dart';

final Provider<BudgetsRepository> budgetsRepositoryProvider =
    Provider<BudgetsRepository>(
      (Ref ref) => BudgetsRepository(ref.watch(apiClientProvider)),
    );

/// `GET /budgets/{project_id}`, cacheado por proyecto.
final AutoDisposeFutureProviderFamily<List<Budget>, String>
projectBudgetsProvider = FutureProvider.autoDispose.family<List<Budget>, String>(
  (Ref ref, String projectId) =>
      ref.watch(budgetsRepositoryProvider).fetchByProject(projectId),
);
