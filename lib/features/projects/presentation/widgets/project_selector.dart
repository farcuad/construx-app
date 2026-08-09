import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/project_scope.dart';
import '../../application/projects_controller.dart';
import '../../domain/project.dart';

/// Desplegable de proyecto, al estilo de un `<select>` de HTML.
///
/// Escribe en [selectedProjectIdProvider], que es la selección compartida por
/// el panel y por todos los módulos que trabajan sobre una obra: elegir aquí
/// cambia lo que se ve en Gastos, Cronograma, Fotos…
///
/// Se usa [DropdownButton] y no una hoja inferior porque el menú se despliega
/// justo encima del control, como en la web; sus entradas son una sola fila de
/// texto, así que construirlas es barato incluso con muchas obras.
class ProjectSelector extends ConsumerWidget {
  const ProjectSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Project> projects =
        ref.watch(projectsControllerProvider).valueOrNull ?? const <Project>[];
    final Project? active = ref.watch(activeProjectProvider);
    if (active == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.apartment_rounded,
            size: 19,
            color: AppColors.orange,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: active.id,
                isExpanded: true,
                // Sin `isDense`: el control necesita los 48 px de alto mínimo
                // para las dos líneas del rótulo, y además es la altura táctil
                // recomendada.
                borderRadius: AppTheme.borderRadius,
                dropdownColor: AppColors.surfaceHigh,
                focusColor: Colors.transparent,
                icon: const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.textSecondary,
                ),
                // Sin esto el desplegable se leería como un campo de texto más;
                // el rótulo aclara que lo que se elige es el ámbito de la
                // pantalla entera.
                hint: const Text('Elige una obra'),
                selectedItemBuilder: (BuildContext context) => <Widget>[
                  for (final Project project in projects)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _SelectedLabel(name: project.name),
                    ),
                ],
                items: <DropdownMenuItem<String>>[
                  for (final Project project in projects)
                    DropdownMenuItem<String>(
                      value: project.id,
                      child: Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14.5),
                      ),
                    ),
                ],
                onChanged: projects.length < 2
                    ? null
                    : (String? id) {
                        if (id != null) {
                          ref.read(selectedProjectIdProvider.notifier).state =
                              id;
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que se ve en el control cuando el menú está cerrado: rótulo pequeño
/// encima del nombre de la obra.
class _SelectedLabel extends StatelessWidget {
  const _SelectedLabel({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const Text(
        'PROYECTO',
        style: TextStyle(
          color: AppColors.textDisabled,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: 1),
      Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

/// Selector + contenido que depende de la obra elegida.
///
/// Resuelve de una vez los dos casos que si no repetiría cada módulo por obra:
/// que la empresa aún no tenga proyectos y que la lista todavía esté cargando.
class ProjectScope extends ConsumerWidget {
  const ProjectScope({
    required this.builder,
    this.emptyMessage =
        'Este módulo trabaja sobre una obra. Crea la primera para empezar.',
    super.key,
  });

  final Widget Function(BuildContext context, Project project) builder;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Project>> projects = ref.watch(
      projectsControllerProvider,
    );
    final Project? active = ref.watch(activeProjectProvider);

    if (active == null) {
      return switch (projects) {
        AsyncLoading<List<Project>>() => const LoadingView(),
        AsyncError<List<Project>>() => ErrorView(
          message: 'No se pudieron cargar los proyectos.',
          onRetry: () =>
              ref.read(projectsControllerProvider.notifier).refresh(),
        ),
        _ => EmptyState(
          icon: Icons.apartment_rounded,
          title: 'Aún no hay proyectos',
          message: emptyMessage,
        ),
      };
    }

    return Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: ProjectSelector(),
        ),
        Expanded(child: builder(context, active)),
      ],
    );
  }
}
