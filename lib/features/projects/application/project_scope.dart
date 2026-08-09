import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/project.dart';
import 'projects_controller.dart';

/// Proyecto elegido en el selector.
///
/// `null` significa «ninguno elegido todavía»; [activeProjectProvider] lo
/// resuelve al primero de la lista.
final StateProvider<String?> selectedProjectIdProvider = StateProvider<String?>(
  (Ref ref) => null,
);

/// Proyecto sobre el que trabajan el panel y los módulos por obra.
///
/// Es **una sola selección para toda la app**: si el usuario elige una obra en
/// el panel y entra en Gastos, ve los gastos de esa misma obra sin tener que
/// volver a elegirla.
///
/// Se deriva en lugar de escribirse desde la UI: así nunca queda apuntando a un
/// proyecto que se acaba de borrar, y no hace falta un `addPostFrameCallback`
/// para elegir el primero al cargar.
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
