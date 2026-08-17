import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';
import '../domain/project_dashboard_model.dart';

final Provider<ProjectsRepository> projectsRepositoryProvider =
    Provider<ProjectsRepository>(
      (Ref ref) => ProjectsRepository(ref.watch(apiClientProvider)),
    );

/// Lista de proyectos de la empresa.
///
/// `AsyncNotifier` da gratis los estados de carga/error/dato y el manejo de
/// `AsyncValue.guard`, evitando `try/catch` repartidos por la UI.
class ProjectsController extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() =>
      ref.watch(projectsRepositoryProvider).fetchAll();

  ProjectsRepository get _repository => ref.read(projectsRepositoryProvider);

  /// Recarga la lista mostrando el spinner de refresco.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_repository.fetchAll);
  }

  /// Crea un proyecto y lo inserta al principio de la lista sin recargar todo.
  Future<Project> create(Project project) async {
    final Project created = await _repository.create(project);
    state = AsyncValue<List<Project>>.data(<Project>[
      created,
      ...state.valueOrNull ?? const <Project>[],
    ]);
    return created;
  }

  /// Actualiza un proyecto y lo reemplaza en la lista en memoria.
  Future<Project> updateProject(Project project) async {
    final Project updated = await _repository.update(project);
    final List<Project> current = state.valueOrNull ?? const <Project>[];
    state = AsyncValue<List<Project>>.data(<Project>[
      for (final Project p in current)
        if (p.id == updated.id) updated else p,
    ]);
    return updated;
  }

  /// Elimina un proyecto. Si el backend responde `409` la excepción se
  /// propaga y la lista queda intacta.
  Future<void> delete(String id) async {
    await _repository.delete(id);
    final List<Project> current = state.valueOrNull ?? const <Project>[];
    state = AsyncValue<List<Project>>.data(
      current.where((Project p) => p.id != id).toList(growable: false),
    );
  }
}

final AsyncNotifierProvider<ProjectsController, List<Project>>
projectsControllerProvider =
    AsyncNotifierProvider<ProjectsController, List<Project>>(
      ProjectsController.new,
    );

/// KPIs financieros de un proyecto. `family` cachea por `projectId` y
/// `autoDispose` libera la memoria al salir de la pantalla de detalle.
final AutoDisposeFutureProviderFamily<ProjectDashboardModel, String>
projectKpisProvider =
    FutureProvider.autoDispose.family<ProjectDashboardModel, String>(
      (Ref ref, String projectId) =>
          ref.watch(projectsRepositoryProvider).fetchKpis(projectId),
    );
