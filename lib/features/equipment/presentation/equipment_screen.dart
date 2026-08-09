import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/resources_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../application/equipment_providers.dart';
import '../domain/equipment_models.dart';

/// Maquinaria de la empresa (`GET /equipment`).
///
/// Al tocar una máquina se abre su hoja con asignaciones y mantenimientos, que
/// son dos peticiones aparte: así la lista carga con una sola llamada.
class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  static const String routeName = 'equipment';
  static const String routePath = '/equipment';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Equipment>> equipment = ref.watch(equipmentProvider);
    final Map<String, String> types = <String, String>{
      for (final EquipmentType t
          in ref.watch(equipmentTypesProvider).valueOrNull ??
              const <EquipmentType>[])
        t.id: t.name,
    };

    final EquipmentStrings strings = ref.watch(stringsProvider).equipment;

    return ModuleScaffold(
      title: 'Maquinaria',
      currentPath: routePath,
      onRefresh: () {
        ref.invalidate(equipmentProvider);
        ref.invalidate(equipmentTypesProvider);
      },
      body: AsyncSection<List<Equipment>>(
        value: equipment,
        errorMessage: strings.loadError,
        onRetry: () => ref.invalidate(equipmentProvider),
        builder: (List<Equipment> data) => data.isEmpty
            ? EmptyState(
                icon: Icons.agriculture_rounded,
                title: strings.emptyTitle,
                message: strings.emptyMessage,
              )
            : ModuleList(
                itemCount: data.length,
                onRefresh: () async => ref.invalidate(equipmentProvider),
                itemBuilder: (BuildContext context, int index) =>
                    _EquipmentCard(
                      equipment: data[index],
                      typeName: types[data[index].typeId],
                    ),
              ),
      ),
    );
  }
}

/// Color del estado: verde disponible, naranja asignada, rojo en taller.
Color _statusColor(String status) => switch (status) {
  EquipmentStatus.available => AppColors.success,
  EquipmentStatus.assigned => AppColors.orangeNeon,
  EquipmentStatus.inMaintenance => AppColors.danger,
  _ => AppColors.textSecondary,
};

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.equipment, this.typeName});

  final Equipment equipment;
  final String? typeName;

  @override
  Widget build(BuildContext context) {
    final Color color = _statusColor(equipment.status);

    return AppCard(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) =>
            _EquipmentSheet(equipment: equipment),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LeadingIcon(icon: Icons.agriculture_rounded, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        equipment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      label: equipment.status.isEmpty ? '—' : equipment.status,
                      color: color,
                    ),
                  ],
                ),
                if (typeName != null)
                  InfoLine(icon: Icons.category_outlined, text: typeName!),
                if (equipment.plateNumber.isNotEmpty)
                  InfoLine(
                    icon: Icons.pin_outlined,
                    text: equipment.plateNumber,
                  ),
                InfoLine(
                  icon: Icons.info_outline_rounded,
                  text: <String>[
                    if (equipment.brand.isNotEmpty) equipment.brand,
                    if (equipment.model.isNotEmpty) equipment.model,
                    if (equipment.ownershipType.isNotEmpty)
                      equipment.ownershipType,
                  ].join(' · '),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ficha de una máquina: asignaciones a obra y historial de mantenimiento.
class _EquipmentSheet extends ConsumerWidget {
  const _EquipmentSheet({required this.equipment});

  final Equipment equipment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<EquipmentAssignment>> assignments = ref.watch(
      equipmentAssignmentsProvider(equipment.id),
    );
    final AsyncValue<List<MaintenanceRecord>> maintenances = ref.watch(
      equipmentMaintenancesProvider(equipment.id),
    );
    final EquipmentStrings strings = ref.watch(stringsProvider).equipment;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: <Widget>[
                  LeadingIcon(
                    icon: Icons.agriculture_rounded,
                    color: _statusColor(equipment.status),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      equipment.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: <Widget>[
                  _SheetTitle(strings.assignments),
                  AsyncSection<List<EquipmentAssignment>>(
                    value: assignments,
                    errorMessage: strings.assignmentsError,
                    onRetry: () => ref.invalidate(
                      equipmentAssignmentsProvider(equipment.id),
                    ),
                    builder: (List<EquipmentAssignment> data) => data.isEmpty
                        ? _SheetEmpty(strings.noAssignments)
                        : Column(
                            children: <Widget>[
                              for (final EquipmentAssignment a in data)
                                InfoLine(
                                  icon: Icons.event_available_rounded,
                                  text:
                                      '${Fmt.date(a.startDate)} → '
                                      '${Fmt.date(a.endDate)}',
                                  top: 8,
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 22),
                  _SheetTitle(strings.maintenances),
                  AsyncSection<List<MaintenanceRecord>>(
                    value: maintenances,
                    errorMessage: strings.maintenancesError,
                    onRetry: () => ref.invalidate(
                      equipmentMaintenancesProvider(equipment.id),
                    ),
                    builder: (List<MaintenanceRecord> data) => data.isEmpty
                        ? _SheetEmpty(strings.noMaintenances)
                        : Column(
                            children: <Widget>[
                              for (final MaintenanceRecord m in data)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              m.maintenanceType.isEmpty
                                                  ? strings.untitledMaintenance
                                                  : m.maintenanceType,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            InfoLine(
                                              icon: Icons.event_rounded,
                                              text: Fmt.date(m.maintenanceDate),
                                              top: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        Fmt.money(m.cost),
                                        style: const TextStyle(
                                          color: AppColors.warning,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: AppColors.textDisabled,
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );
}

class _SheetEmpty extends StatelessWidget {
  const _SheetEmpty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    ),
  );
}
