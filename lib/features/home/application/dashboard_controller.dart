import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/application/projects_controller.dart';
import '../../projects/domain/project.dart';

/// Proyecto elegido en el selector del panel.
///
/// `null` significa «ninguno elegido todavía»; [activeProjectProvider] lo
/// resuelve al primero de la lista.
final StateProvider<String?> selectedProjectIdProvider = StateProvider<String?>(
  (Ref ref) => null,
);

/// Proyecto cuyos indicadores se están mostrando.
///
/// Se deriva en lugar de escribirse desde la UI: así el panel nunca queda
/// apuntando a un proyecto que se acaba de borrar, y no hace falta un
/// `addPostFrameCallback` para elegir el primero al cargar.
final Provider<Project?> activeProjectProvider = Provider<Project?>((Ref ref) {
  final List<Project> projects =
      ref.watch(projectsControllerProvider).valueOrNull ?? const <Project>[];
  if (projects.isEmpty) return null;

  final String? selectedId = ref.watch(selectedProjectIdProvider);
  for (final Project project in projects) {
    if (project.id == selectedId) return project;
  }
  return projects.first;
});
