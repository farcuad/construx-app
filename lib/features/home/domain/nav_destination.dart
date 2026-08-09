import 'package:flutter/material.dart';

import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';

/// Una pestaña de la barra inferior.
///
/// Es un catálogo aparte del de módulos ([kAppModules]) porque la barra no es
/// un resumen del menú: incluye el panel y los ajustes, que no son módulos, y
/// deja fuera casi todos los que sí lo son.
@immutable
class NavDestination {
  const NavDestination({
    required this.id,
    required this.path,
    required this.icon,
    required this.fallbackLabel,
    this.requiredPermissions = const <String>[],
  });

  /// Coincide con el id del módulo cuando la pestaña abre uno, para poder
  /// reutilizar su traducción.
  final String id;

  final String path;
  final IconData icon;

  /// Rótulo en español, por si el idioma activo no tradujo este id.
  final String fallbackLabel;

  /// Vacío = visible siempre (el panel y los ajustes no piden permiso).
  final List<String> requiredPermissions;

  bool isVisibleFor(AuthUser user) =>
      requiredPermissions.isEmpty || user.canAny(requiredPermissions);
}

/// Las cuatro vistas que están siempre a un toque.
///
/// El criterio para elegirlas fue el uso diario, no la importancia del módulo:
/// el **panel** es la portada, **proyectos** es de donde cuelga todo lo demás,
/// **gastos** es el módulo que más se escribe desde la obra, y **ajustes**
/// tiene que estar alcanzable desde cualquier sitio porque ahí vive el cierre
/// de sesión. El resto del ERP sigue en el menú lateral.
const List<NavDestination> kNavDestinations = <NavDestination>[
  NavDestination(
    id: 'panel',
    path: '/home',
    icon: Icons.space_dashboard_rounded,
    fallbackLabel: 'Panel',
  ),
  NavDestination(
    id: 'projects',
    path: '/projects',
    icon: Icons.apartment_rounded,
    fallbackLabel: 'Proyectos',
    requiredPermissions: <String>[Perm.projectsRead],
  ),
  NavDestination(
    id: 'expenses',
    path: '/expenses',
    icon: Icons.payments_rounded,
    fallbackLabel: 'Gastos',
    requiredPermissions: <String>[Perm.expensesRead],
  ),
  NavDestination(
    id: 'settings',
    path: '/settings',
    icon: Icons.settings_rounded,
    fallbackLabel: 'Ajustes',
  ),
];

/// Pestañas que [user] puede abrir, en el orden del catálogo.
List<NavDestination> navDestinationsFor(AuthUser user) => kNavDestinations
    .where((NavDestination d) => d.isVisibleFor(user))
    .toList(growable: false);
