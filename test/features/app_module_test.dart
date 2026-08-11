import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_constructora/features/auth/domain/auth_user.dart';
import 'package:mi_app_constructora/features/home/domain/app_module.dart';

void main() {
  AuthUser user(String role) =>
      AuthUser(id: '1', name: 'Test', email: 't@t.com', role: role);

  List<String> idsFor(AuthUser u) =>
      modulesFor(u).map((AppModule m) => m.id).toList();

  test('el administrador ve todos los módulos', () {
    expect(modulesFor(user('Administrador')), hasLength(kAppModules.length));
  });

  test('un cargo que la app no conoce no ve ningún módulo', () {
    expect(modulesFor(user('Pasante')), isEmpty);
  });

  test('el supervisor ve la obra pero no el dinero', () {
    final List<String> ids = idsFor(user('Supervisor'));

    expect(ids, containsAll(<String>['projects', 'inventory', 'attendance']));
    expect(ids, isNot(contains('users')));
    expect(ids, isNot(contains('invoices')));
    expect(ids, isNot(contains('budgets')));
  });

  test('almacén ve inventario porque tiene el permiso de gestión', () {
    expect(idsFor(user('Almacén')), contains('inventory'));
  });

  test('los módulos conservan el orden del catálogo', () {
    final List<String> ids = idsFor(user('Administrador'));
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
