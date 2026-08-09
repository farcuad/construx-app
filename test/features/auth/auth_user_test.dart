import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_constructora/features/auth/domain/auth_user.dart';
import 'package:mi_app_constructora/features/auth/domain/permissions.dart';
import 'package:mi_app_constructora/features/auth/domain/session.dart';

import '../../helpers/test_helpers.dart';

void main() {
  AuthUser user(List<String> permissions) => AuthUser(
    id: '1',
    name: 'María Gómez',
    email: 'maria@xyz.com',
    role: 'Ingeniero',
    permissions: permissions.toSet(),
  );

  group('AuthUser · permisos', () {
    test('el comodín concede cualquier permiso', () {
      final AuthUser admin = user(<String>[Perm.wildcard]);
      expect(admin.isAdmin, isTrue);
      expect(admin.can(Perm.invoicesCancel), isTrue);
      expect(admin.can('permiso:inventado'), isTrue);
    });

    test('un rol concreto solo concede sus permisos', () {
      final AuthUser engineer = user(<String>[
        Perm.projectsRead,
        Perm.budgetsRead,
      ]);
      expect(engineer.isAdmin, isFalse);
      expect(engineer.can(Perm.projectsRead), isTrue);
      expect(engineer.can(Perm.projectsDelete), isFalse);
    });

    test('canAny acepta si tiene al menos uno', () {
      final AuthUser warehouse = user(<String>[Perm.inventoryManage]);
      expect(
        warehouse.canAny(<String>[Perm.inventoryRead, Perm.inventoryManage]),
        isTrue,
      );
      expect(
        warehouse.canAny(<String>[Perm.usersRead, Perm.auditsRead]),
        isFalse,
      );
    });

    test('canAny con comodín siempre acepta', () {
      expect(
        user(<String>[Perm.wildcard]).canAny(<String>[Perm.auditsRead]),
        isTrue,
      );
    });

    test('un usuario sin permisos no puede nada', () {
      final AuthUser none = user(<String>[]);
      expect(none.can(Perm.projectsRead), isFalse);
      expect(none.canAny(<String>[Perm.projectsRead]), isFalse);
    });
  });

  group('AuthUser · serialización', () {
    test('fromJson lee la respuesta de /login', () {
      final AuthUser parsed = AuthUser.fromJson(<String, dynamic>{
        'id': 'a1b2',
        'name': 'Andrés Pérez',
        'email': 'andres@xyz.com',
        'role': 'Administrador',
        'permissions': <String>['*'],
      });

      expect(parsed.id, 'a1b2');
      expect(parsed.isAdmin, isTrue);
    });

    test('tolera campos ausentes o nulos', () {
      final AuthUser parsed = AuthUser.fromJson(<String, dynamic>{});
      expect(parsed.id, '');
      expect(parsed.permissions, isEmpty);
    });

    test('toJson/fromJson es de ida y vuelta', () {
      final AuthUser original = user(<String>[
        Perm.projectsRead,
        Perm.budgetsRead,
      ]);
      expect(AuthUser.fromJson(original.toJson()), original);
    });
  });

  group('AuthUser · iniciales', () {
    test('toma dos iniciales de nombre y apellido', () {
      expect(user(<String>[]).initials, 'MG');
    });

    test('con un solo nombre toma una inicial', () {
      final AuthUser single = AuthUser(
        id: '1',
        name: 'Andrés',
        email: 'a@b.com',
        role: 'Gerente',
        permissions: const <String>{},
      );
      expect(single.initials, 'A');
    });

    test('sin nombre devuelve un interrogante', () {
      final AuthUser anon = AuthUser(
        id: '1',
        name: '   ',
        email: 'a@b.com',
        role: '',
        permissions: const <String>{},
      );
      expect(anon.initials, '?');
    });
  });

  group('Session · JWT', () {
    test('lee la expiración del claim exp', () {
      final DateTime exp = DateTime.utc(2026, 12, 31, 10);
      final Session session = Session(
        token: fakeJwt(expiresAt: exp),
        user: user(<String>[]),
      );

      expect(
        session.expiresAt!.millisecondsSinceEpoch ~/ 1000,
        exp.millisecondsSinceEpoch ~/ 1000,
      );
      expect(session.isExpired, isFalse);
    });

    test('detecta un token expirado', () {
      final Session session = Session(
        token: fakeJwt(
          expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ),
        user: user(<String>[]),
      );
      expect(session.isExpired, isTrue);
    });

    test('considera expirado un token que muere en menos de un minuto', () {
      final Session session = Session(
        token: fakeJwt(
          expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 20)),
        ),
        user: user(<String>[]),
      );
      expect(session.isExpired, isTrue);
    });

    test('expone el company_id del token', () {
      final Session session = Session(
        token: fakeJwt(companyId: '6f3e-empresa'),
        user: user(<String>[]),
      );
      expect(session.companyId, '6f3e-empresa');
    });

    test('un token malformado devuelve null en los claims y no expira', () {
      final Session session = Session(
        token: 'esto-no-es-un-jwt',
        user: user(<String>[]),
      );
      expect(session.expiresAt, isNull);
      expect(session.companyId, isNull);
      expect(session.isExpired, isFalse);
    });
  });
}
