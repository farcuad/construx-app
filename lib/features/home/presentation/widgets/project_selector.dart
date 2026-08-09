import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/project.dart';
import '../../application/dashboard_controller.dart';

/// Selector del proyecto cuyos indicadores muestra el panel.
///
/// Abre una hoja inferior en vez de un `DropdownButton` porque la lista puede
/// ser larga: la hoja usa `ListView.builder` y solo construye lo visible.
class ProjectSelector extends ConsumerWidget {
  const ProjectSelector({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
    color: AppColors.surface,
    borderRadius: AppTheme.borderRadius,
    child: InkWell(
      borderRadius: AppTheme.borderRadius,
      onTap: () => _openPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: AppTheme.borderRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.all(Radius.circular(11)),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                size: 19,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'PROYECTO',
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.unfold_more_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final List<Project> projects =
        ref.read(projectsControllerProvider).valueOrNull ?? const <Project>[];
    if (projects.length < 2) return;

    final String? chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _ProjectPickerSheet(
        projects: projects,
        selectedId: project.id,
      ),
    );
    if (chosen != null) {
      ref.read(selectedProjectIdProvider.notifier).state = chosen;
    }
  }
}

class _ProjectPickerSheet extends StatelessWidget {
  const _ProjectPickerSheet({required this.projects, required this.selectedId});

  final List<Project> projects;
  final String selectedId;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      // Nunca más de dos tercios de la pantalla: la hoja no debe tapar todo.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.66,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Elige un proyecto',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: projects.length,
              itemBuilder: (BuildContext context, int index) {
                final Project project = projects[index];
                final bool selected = project.id == selectedId;
                return ListTile(
                  onTap: () => Navigator.of(context).pop(project.id),
                  selected: selected,
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? AppColors.orangeNeon
                        : AppColors.textDisabled,
                    size: 20,
                  ),
                  title: Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? AppColors.orangeNeon
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: project.location.isEmpty
                      ? null
                      : Text(
                          project.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                  trailing: Text(
                    Fmt.moneyCompact(project.budget),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
