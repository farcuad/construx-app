import 'package:flutter/material.dart';

import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';

/// Un módulo del ERP mostrado en el panel principal.
///
/// [requiredPermissions] refleja los permisos que el backend exige para la
/// lectura del módulo; basta con tener **uno** de ellos para verlo. El filtrado
/// en el cliente es solo cosmético: el backend revalida en cada petición.
@immutable
class AppModule {
  const AppModule({
    required this.id,
    required this.title,
    required this.icon,
    required this.requiredPermissions,
    this.routePath,
    this.accent,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<String> requiredPermissions;

  /// Ruta de go_router. `null` mientras el módulo no esté implementado; el
  /// menú lateral lo marca entonces como «Pronto» en vez de navegar.
  final String? routePath;

  /// Color de acento de la tarjeta.
  final Color? accent;

  /// `true` si el módulo ya tiene pantalla.
  bool get isAvailable => routePath != null;

  bool isVisibleFor(AuthUser user) => user.canAny(requiredPermissions);
}

/// Catálogo completo de módulos, en el orden en que se muestran.
///
/// Los avisos **no** están aquí a propósito: se llega a ellos por la campana de
/// la cabecera del panel, no por el menú.
const List<AppModule> kAppModules = <AppModule>[
  AppModule(
    id: 'projects',
    title: 'Proyectos',
    icon: Icons.apartment_rounded,
    requiredPermissions: <String>[Perm.projectsRead],
    routePath: '/projects',
  ),
  AppModule(
    id: 'clients',
    title: 'Clientes',
    icon: Icons.handshake_rounded,
    requiredPermissions: <String>[Perm.clientsRead],
    routePath: '/clients',
  ),
  AppModule(
    id: 'expenses',
    title: 'Gastos',
    icon: Icons.payments_rounded,
    requiredPermissions: <String>[Perm.expensesRead],
    routePath: '/expenses',
  ),
  AppModule(
    id: 'suppliers',
    title: 'Proveedores',
    icon: Icons.local_shipping_rounded,
    requiredPermissions: <String>[Perm.suppliersRead],
    routePath: '/suppliers',
  ),
  AppModule(
    id: 'inventory',
    title: 'Inventario',
    icon: Icons.inventory_2_rounded,
    requiredPermissions: <String>[Perm.inventoryRead, Perm.inventoryManage],
    routePath: '/inventory',
  ),
  AppModule(
    id: 'equipment',
    title: 'Maquinaria',
    icon: Icons.agriculture_rounded,
    requiredPermissions: <String>[Perm.equipmentRead],
    routePath: '/equipment',
  ),
  AppModule(
    id: 'personnel',
    title: 'Personal',
    icon: Icons.badge_rounded,
    requiredPermissions: <String>[Perm.personnelRead],
    routePath: '/personnel',
  ),
  AppModule(
    id: 'attendance',
    title: 'Asistencia',
    icon: Icons.how_to_reg_rounded,
    requiredPermissions: <String>[Perm.attendanceRead, Perm.attendanceMark],
    routePath: '/attendance',
  ),
  AppModule(
    id: 'contractors',
    title: 'Contratistas',
    icon: Icons.groups_rounded,
    requiredPermissions: <String>[Perm.contractorsRead],
    routePath: '/contractors',
  ),
  AppModule(
    id: 'schedule',
    title: 'Cronograma',
    icon: Icons.calendar_month_rounded,
    requiredPermissions: <String>[Perm.scheduleRead],
    routePath: '/schedule',
  ),
  AppModule(
    id: 'progress',
    title: 'Avance de obra',
    icon: Icons.trending_up_rounded,
    requiredPermissions: <String>[Perm.progressRead],
    routePath: '/progress',
  ),
  AppModule(
    id: 'photos',
    title: 'Fotos',
    icon: Icons.photo_camera_rounded,
    requiredPermissions: <String>[Perm.photosRead],
    routePath: '/photos',
  ),
  AppModule(
    id: 'invoices',
    title: 'Facturación',
    icon: Icons.receipt_long_rounded,
    requiredPermissions: <String>[Perm.invoicesRead],
    routePath: '/invoices',
  ),
  AppModule(
    id: 'users',
    title: 'Usuarios',
    icon: Icons.manage_accounts_rounded,
    requiredPermissions: <String>[Perm.usersRead],
    routePath: '/users',
  ),
  AppModule(
    id: 'audits',
    title: 'Auditoría',
    icon: Icons.fact_check_rounded,
    requiredPermissions: <String>[Perm.auditsRead],
    routePath: '/audits',
  ),
];

/// El módulo cuya pantalla vive en [path], o `null` si esa ruta no es la de un
/// módulo (el panel, los ajustes, una subruta de detalle…).
AppModule? moduleForPath(String path) {
  for (final AppModule module in kAppModules) {
    if (module.routePath == path) return module;
  }
  return null;
}

/// Módulos visibles para [user], preservando el orden del catálogo.
List<AppModule> modulesFor(AuthUser user) => kAppModules
    .where((AppModule m) => m.isVisibleFor(user))
    .toList(growable: false);
