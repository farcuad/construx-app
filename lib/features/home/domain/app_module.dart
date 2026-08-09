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

  /// Ruta de go_router. `null` mientras el módulo no esté implementado.
  final String? routePath;

  /// Color de acento de la tarjeta.
  final Color? accent;

  /// `true` si el módulo ya tiene pantalla.
  bool get isAvailable => routePath != null;

  bool isVisibleFor(AuthUser user) => user.canAny(requiredPermissions);
}

/// Catálogo completo de módulos, en el orden en que se muestran.
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
    id: 'budgets',
    title: 'Presupuestos',
    icon: Icons.request_quote_rounded,
    requiredPermissions: <String>[Perm.budgetsRead],
  ),
  AppModule(
    id: 'expenses',
    title: 'Gastos',
    icon: Icons.payments_rounded,
    requiredPermissions: <String>[Perm.expensesRead],
  ),
  AppModule(
    id: 'purchases',
    title: 'Órdenes de compra',
    icon: Icons.shopping_cart_checkout_rounded,
    requiredPermissions: <String>[Perm.purchasesRead],
  ),
  AppModule(
    id: 'suppliers',
    title: 'Proveedores',
    icon: Icons.local_shipping_rounded,
    requiredPermissions: <String>[Perm.suppliersRead],
  ),
  AppModule(
    id: 'inventory',
    title: 'Inventario',
    icon: Icons.inventory_2_rounded,
    requiredPermissions: <String>[Perm.inventoryRead, Perm.inventoryManage],
  ),
  AppModule(
    id: 'equipment',
    title: 'Maquinaria',
    icon: Icons.agriculture_rounded,
    requiredPermissions: <String>[Perm.equipmentRead],
  ),
  AppModule(
    id: 'personnel',
    title: 'Personal',
    icon: Icons.badge_rounded,
    requiredPermissions: <String>[Perm.personnelRead],
  ),
  AppModule(
    id: 'attendance',
    title: 'Asistencia',
    icon: Icons.how_to_reg_rounded,
    requiredPermissions: <String>[Perm.attendanceRead, Perm.attendanceMark],
  ),
  AppModule(
    id: 'contractors',
    title: 'Contratistas',
    icon: Icons.groups_rounded,
    requiredPermissions: <String>[Perm.contractorsRead],
  ),
  AppModule(
    id: 'schedule',
    title: 'Cronograma',
    icon: Icons.calendar_month_rounded,
    requiredPermissions: <String>[Perm.scheduleRead],
  ),
  AppModule(
    id: 'progress',
    title: 'Avance de obra',
    icon: Icons.trending_up_rounded,
    requiredPermissions: <String>[Perm.progressRead],
  ),
  AppModule(
    id: 'photos',
    title: 'Fotos',
    icon: Icons.photo_camera_rounded,
    requiredPermissions: <String>[Perm.photosRead],
  ),
  AppModule(
    id: 'invoices',
    title: 'Facturación',
    icon: Icons.receipt_long_rounded,
    requiredPermissions: <String>[Perm.invoicesRead],
  ),
  AppModule(
    id: 'documents',
    title: 'Documentos',
    icon: Icons.folder_copy_rounded,
    requiredPermissions: <String>[Perm.documentsRead],
  ),
  AppModule(
    id: 'users',
    title: 'Usuarios',
    icon: Icons.manage_accounts_rounded,
    requiredPermissions: <String>[Perm.usersRead],
  ),
  AppModule(
    id: 'audits',
    title: 'Auditoría',
    icon: Icons.fact_check_rounded,
    requiredPermissions: <String>[Perm.auditsRead],
  ),
];

/// Módulos visibles para [user], preservando el orden del catálogo.
List<AppModule> modulesFor(AuthUser user) => kAppModules
    .where((AppModule m) => m.isVisibleFor(user))
    .toList(growable: false);
