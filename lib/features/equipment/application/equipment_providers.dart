import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/equipment_repository.dart';
import '../domain/equipment_models.dart';

final Provider<EquipmentRepository> equipmentRepositoryProvider =
    Provider<EquipmentRepository>(
      (Ref ref) => EquipmentRepository(ref.watch(apiClientProvider)),
    );

/// `GET /equipment`.
final AutoDisposeFutureProvider<List<Equipment>> equipmentProvider =
    FutureProvider.autoDispose<List<Equipment>>(
      (Ref ref) => ref.watch(equipmentRepositoryProvider).fetchAll(),
    );

/// `GET /equipment/types`.
final AutoDisposeFutureProvider<List<EquipmentType>> equipmentTypesProvider =
    FutureProvider.autoDispose<List<EquipmentType>>(
      (Ref ref) => ref.watch(equipmentRepositoryProvider).fetchTypes(),
    );

/// `GET /equipment/assignments/{equipment_id}`.
final AutoDisposeFutureProviderFamily<List<EquipmentAssignment>, String>
equipmentAssignmentsProvider =
    FutureProvider.autoDispose.family<List<EquipmentAssignment>, String>(
      (Ref ref, String equipmentId) =>
          ref.watch(equipmentRepositoryProvider).fetchAssignments(equipmentId),
    );

/// `GET /equipment/maintenances/{equipment_id}`.
final AutoDisposeFutureProviderFamily<List<MaintenanceRecord>, String>
equipmentMaintenancesProvider =
    FutureProvider.autoDispose.family<List<MaintenanceRecord>, String>(
      (Ref ref, String equipmentId) =>
          ref.watch(equipmentRepositoryProvider).fetchMaintenances(equipmentId),
    );
