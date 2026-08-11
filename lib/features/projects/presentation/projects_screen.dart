import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/admin_strings.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../clients/application/clients_controller.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../application/projects_controller.dart';
import '../domain/project.dart';
import 'project_form_sheet.dart';

/// Listado de proyectos (`GET /projects`) con creación, edición y borrado.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  static const String routeName = 'projects';
  static const String routePath = '/projects';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Project>> projects = ref.watch(
      projectsControllerProvider,
    );
    final AuthUser? user = ref.watch(currentUserProvider);
    final AppStrings strings = ref.watch(stringsProvider);
    final bool canCreate = user?.can(Perm.projectsCreate) ?? false;

    // El menú lateral sustituye a la flecha de volver: desde el panel se
    // navega con `go`, así que no hay pila a la que retroceder.
    return ModuleScaffold(
      title: 'Proyectos',
      currentPath: routePath,
      onRefresh: () => ref.read(projectsControllerProvider.notifier).refresh(),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => showProjectFormSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(strings.common.newItem),
            )
          : null,
      body: switch (projects) {
        AsyncData<List<Project>>(:final List<Project> value) => _ProjectsList(
          projects: value,
          canCreate: canCreate,
        ),
        AsyncError<List<Project>>(:final Object error) => ErrorView(
          message: error is ApiException
              ? error.message
              : strings.projects.loadError,
          onRetry: () =>
              ref.read(projectsControllerProvider.notifier).refresh(),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _ProjectsList extends ConsumerWidget {
  const _ProjectsList({required this.projects, required this.canCreate});

  final List<Project> projects;
  final bool canCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectsStrings strings = ref.watch(stringsProvider).projects;

    if (projects.isEmpty) {
      return EmptyState(
        icon: Icons.apartment_rounded,
        title: strings.emptyTitle,
        message: canCreate ? strings.emptyCanCreate : strings.emptyReadOnly,
      );
    }

    // El índice de clientes se resuelve una vez y se pasa a las filas, en
    // lugar de que cada fila observe la lista completa de clientes.
    final Map<String, String> clientNames = ref.watch(clientNamesProvider);

    return RefreshIndicator(
      color: AppColors.orangeNeon,
      backgroundColor: AppColors.surface,
      onRefresh: ref.read(projectsControllerProvider.notifier).refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: projects.length,
        // Con `itemExtent` no se puede porque las tarjetas varían de alto;
        // `separated` + builder ya construye solo lo visible.
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final Project project = projects[index];
          return _ProjectCard(
            project: project,
            clientName: clientNames[project.clientId],
          );
        },
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project, this.clientName});

  final Project project;
  final String? clientName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    final bool canUpdate = user?.can(Perm.projectsUpdate) ?? false;
    final bool canDelete = user?.can(Perm.projectsDelete) ?? false;
    final double? progress = project.timeProgress;

    return AppCard(
      onTap: () => context.go('/projects/${project.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  project.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              if (canUpdate || canDelete)
                _ProjectMenu(
                  project: project,
                  canUpdate: canUpdate,
                  canDelete: canDelete,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (clientName != null)
            _MetaRow(icon: Icons.handshake_outlined, text: clientName!),
          if (project.location.isNotEmpty)
            _MetaRow(icon: Icons.place_outlined, text: project.location),
          _MetaRow(
            icon: Icons.event_outlined,
            text:
                '${Fmt.date(project.startDate)}  →  ${Fmt.date(project.endDate)}',
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  Fmt.money(project.budget),
                  style: const TextStyle(
                    color: AppColors.orangeNeon,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (progress != null)
                StatusChip(
                  label: ref
                      .watch(stringsProvider)
                      .projects
                      .termElapsedOf((progress * 100).round()),
                  color: progress >= 1
                      ? AppColors.danger
                      : progress > 0.8
                      ? AppColors.warning
                      : AppColors.cyanNeon,
                ),
            ],
          ),
          if (progress != null) ...<Widget>[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.surfaceHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1 ? AppColors.danger : AppColors.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectMenu extends ConsumerWidget {
  const _ProjectMenu({
    required this.project,
    required this.canUpdate,
    required this.canDelete,
  });

  final Project project;
  final bool canUpdate;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PopupMenuButton<_ProjectAction>(
        icon: const Icon(Icons.more_vert_rounded, size: 20),
        color: AppColors.surfaceHigh,
        onSelected: (_ProjectAction action) => switch (action) {
          _ProjectAction.edit => showProjectFormSheet(
            context,
            project: project,
          ),
          _ProjectAction.delete => _confirmDelete(context, ref),
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_ProjectAction>>[
          if (canUpdate)
            PopupMenuItem<_ProjectAction>(
              value: _ProjectAction.edit,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined, size: 19),
                title: Text(ref.read(stringsProvider).projects.edit),
              ),
            ),
          if (canDelete)
            PopupMenuItem<_ProjectAction>(
              value: _ProjectAction.delete,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: AppColors.danger,
                ),
                title: Text(
                  ref.read(stringsProvider).common.delete,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ),
        ],
      );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ProjectsStrings strings = ref.read(stringsProvider).projects;
    final bool confirmed = await confirmDestructive(
      context,
      title: strings.deleteTitle,
      message: strings.deleteBody(project.name),
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(projectsControllerProvider.notifier).delete(project.id);
      if (context.mounted) showAppToast(context, strings.deleted);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppToast(context, e.message, kind: ToastKind.error);
      }
    }
  }
}

enum _ProjectAction { edit, delete }

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.textDisabled),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    ),
  );
}
