/// Selección de proyecto compartida entre el panel y los módulos por obra.
library;

/// El panel comparte con los módulos por obra la misma selección de proyecto.
///
/// Vive en `projects/application/project_scope.dart` porque ya no es cosa solo
/// del panel; se reexporta aquí para no romper los `import` existentes.
export '../../projects/application/project_scope.dart'
    show activeProjectProvider, selectedProjectIdProvider;
