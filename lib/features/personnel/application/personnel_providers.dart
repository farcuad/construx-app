import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/personnel_repository.dart';
import '../domain/personnel_models.dart';

final Provider<PersonnelRepository> personnelRepositoryProvider =
    Provider<PersonnelRepository>(
      (Ref ref) => PersonnelRepository(ref.watch(apiClientProvider)),
    );

/// `GET /employees`.
final AutoDisposeFutureProvider<List<Employee>> employeesProvider =
    FutureProvider.autoDispose<List<Employee>>(
      (Ref ref) => ref.watch(personnelRepositoryProvider).fetchEmployees(),
    );

/// `GET /positions`.
final AutoDisposeFutureProvider<List<Position>> positionsProvider =
    FutureProvider.autoDispose<List<Position>>(
      (Ref ref) => ref.watch(personnelRepositoryProvider).fetchPositions(),
    );

/// `GET /contracts/{project_id}`, cacheado por proyecto.
final AutoDisposeFutureProviderFamily<List<LaborContract>, String>
projectContractsProvider =
    FutureProvider.autoDispose.family<List<LaborContract>, String>(
      (Ref ref, String projectId) =>
          ref.watch(personnelRepositoryProvider).fetchContracts(projectId),
    );
