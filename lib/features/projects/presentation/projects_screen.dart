import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/neon_background.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../clients/application/clients_controller.dart';
import '../../home/presentation/widgets/app_drawer.dart';
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
    final bool canCreate = user?.can(Perm.projectsCreate) ?? false;

    return Scaffold(
      // El menú lateral sustituye a la flecha de volver: desde el panel se
      // navega con `go`, así que no hay pila a la que retroceder.
      drawer: const AppDrawer(currentPath: routePath),
      appBar: AppBar(
        title: const Text('Proyectos'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(projectsControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => showProjectFormSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo'),
            )
          : null,
      body: NeonBackground(
        child: switch (projects) {
          AsyncData<List<Project>>(:final List<Project> value) =>
            _ProjectsList(projects: value, canCreate: canCreate),
          AsyncError<List<Project>>(:final Object error) => ErrorView(
            message: error is ApiException
                ? error.message
                : 'No se pudieron cargar los proyectos.',
            onRetry: () =>
                ref.read(projectsControllerProvider.notifier).refresh(),
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

class _ProjectsList extends ConsumerWidget {
  const _ProjectsList({required this.projects, required this.canCreate});

  final List<Project> projects;
  final bool canCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (projects.isEmpty) {
      return EmptyState(
        icon: Icons.apartment_rounded,
        title: 'Aún no hay proyectos',
        message: canCreate
            ? 'Crea el primero para empezar a registrar avances, gastos y presupuestos.'
            : 'Cuando tu empresa registre obras, aparecerán aquí.',
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
            _MetaRow(
              icon: Icons.place_outlined,
              text: project.location,
            ),
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
                  label: '${(progress * 100).round()}% del plazo',
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
          _ProjectAction.edit => showProjectFormSheet(context, project: project),
          _ProjectAction.delete => _confirmDelete(context, ref),
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_ProjectAction>>[
          if (canUpdate)
            const PopupMenuItem<_ProjectAction>(
              value: _ProjectAction.edit,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_outlined, size: 19),
                title: Text('Editar'),
              ),
            ),
          if (canDelete)
            const PopupMenuItem<_ProjectAction>(
              value: _ProjectAction.delete,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: AppColors.danger,
                ),
                title: Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ),
        ],
      );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text('Se eliminará «${project.name}». Esta acción no se puede deshacer.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    try {
      await ref.read(projectsControllerProvider.notifier).delete(project.id);
      if (context.mounted) showAppSnackBar(context, 'Proyecto eliminado');
    } on ApiException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message, isError: true);
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
