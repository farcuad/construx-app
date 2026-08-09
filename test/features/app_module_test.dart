import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_constructora/features/auth/domain/auth_user.dart';
import 'package:mi_app_constructora/features/auth/domain/permissions.dart';
import 'package:mi_app_constructora/features/home/domain/app_module.dart';

void main() {
  AuthUser user(List<String> permissions) => AuthUser(
    id: '1',
    name: 'Test',
    email: 't@t.com',
    role: 'Test',
    permissions: permissions.toSet(),
  );

  List<String> idsFor(AuthUser u) =>
      modulesFor(u).map((AppModule m) => m.id).toList();

  test('el administrador ve todos los módulos', () {
    expect(
      modulesFor(user(<String>[Perm.wildcard])),
      hasLength(kAppModules.length),
    );
  });

  test('un usuario sin permisos no ve ningún módulo', () {
    expect(modulesFor(user(<String>[])), isEmpty);
  });

  test('el rol Supervisor ve solo proyectos, inventario y presupuestos', () {
    final List<String> ids = idsFor(
      user(<String>[Perm.projectsRead, Perm.inventoryRead, Perm.budgetsRead]),
    );

    expect(ids, containsAll(<String>['projects', 'inventory', 'budgets']));
    expect(ids, isNot(contains('users')));
    expect(ids, isNot(contains('invoices')));
  });

  test('el rol Almacén ve inventario con solo el permiso de gestión', () {
    expect(idsFor(user(<String>[Perm.inventoryManage])), contains('inventory'));
  });

  test('los módulos conservan el orden del catálogo', () {
    final List<String> ids = idsFor(user(<String>[Perm.wildcard]));
    expect(ids.first, 'projects');
    expect(ids[1], 'clients');
  });

  test('los ids del catálogo son únicos', () {
    final Set<String> ids = kAppModules.map((AppModule m) => m.id).toSet();
    expect(ids, hasLength(kAppModules.length));
  });

  test('cada módulo declara al menos un permiso', () {
    for (final AppModule module in kAppModules) {
      expect(module.requiredPermissions, isNotEmpty, reason: module.id);
    }
  });

  test('proyectos y clientes ya tienen pantalla; el resto está pendiente', () {
    final Iterable<AppModule> available = kAppModules.where(
      (AppModule m) => m.isAvailable,
    );

    expect(
      available.map((AppModule m) => m.id),
      containsAll(<String>['projects', 'clients']),
    );
    for (final AppModule module in available) {
      expect(module.routePath, startsWith('/'), reason: module.id);
    }
  });
}
