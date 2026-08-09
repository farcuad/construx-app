import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/expenses_repository.dart';
import '../domain/expense.dart';

final Provider<ExpensesRepository> expensesRepositoryProvider =
    Provider<ExpensesRepository>(
      (Ref ref) => ExpensesRepository(ref.watch(apiClientProvider)),
    );

/// `GET /expenses/{project_id}`, cacheado por proyecto.
final AutoDisposeFutureProviderFamily<List<Expense>, String>
projectExpensesProvider =
    FutureProvider.autoDispose.family<List<Expense>, String>(
      (Ref ref, String projectId) =>
          ref.watch(expensesRepositoryProvider).fetchByProject(projectId),
    );
