import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_constructora/features/auth/domain/auth_user.dart';
import 'package:mi_app_constructora/features/auth/domain/permissions.dart';
import 'package:mi_app_constructora/features/auth/domain/session.dart';

import '../../helpers/test_helpers.dart';

void main() {
  AuthUser user(String role) => AuthUser(
    id: '1',
    name: 'María Gómez',
    email: 'maria@xyz.com',
    role: role,
  );

  group('AuthUser · permisos', () {
    test('el administrador lo puede todo por el comodín', () {
      final AuthUser admin = user('Administrador');
      expect(admin.isAdmin, isTrue);
      expect(admin.can(Perm.invoicesCancel), isTrue);
      expect(admin.can('permiso:inventado'), isTrue);
    });

    test('un cargo concreto solo concede lo suyo', () {
      final AuthUser engineer = user('Ingeniero');
      expect(engineer.isAdmin, isFalse);
      expect(engineer.can(Perm.projectsRead), isTrue);
      expect(engineer.can(Perm.projectsDelete), isFalse);
    });

    test('canAny acepta si tiene al menos uno', () {
      final AuthUser warehouse = user('Almacén');
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
      expect(user('Administrador').canAny(<String>[Perm.auditsRead]), isTrue);
    });

    test('un cargo desconocido no puede nada', () {
      final AuthUser none = user('Pasante');
      expect(none.can(Perm.projectsRead), isFalse);
      expect(none.canAny(<String>[Perm.projectsRead]), isFalse);
    });
  });

  // Quién puede *escribir* en cada módulo, no solo consultarlo. Se comprueba
  // cargo por cargo —y no solo el que sí puede— porque el fallo que importa es
  // el contrario: que a alguien le aparezca un botón que no le toca.
  group('AuthUser · quién registra', () {
    const List<String> everyRole = <String>[
      'Administrador',
      'Gerente',
      'Ingeniero',
      'Supervisor',
      'Almacén',
      'Compras',
      'Contabilidad',
    ];

    void onlyTheseCan(String permission, Set<String> allowed) {
      for (final String role in everyRole) {
        expect(
          user(role).can(permission),
          allowed.contains(role),
          reason: '$role y $permission',
        );
      }
    }

    test('la lista de asistencia la pasa el supervisor', () {
      onlyTheseCan(Perm.attendanceMark, <String>{
        'Administrador',
        'Supervisor',
      });
    });

    test('el parte de avance lo levanta el supervisor', () {
      onlyTheseCan(Perm.progressCreate, <String>{
        'Administrador',
        'Supervisor',
      });
    });

    test('el inventario lo mueve almacén', () {
      onlyTheseCan(Perm.inventoryManage, <String>{'Administrador', 'Almacén'});
    });

    test('gerencia sigue viendo las existencias aunque no las mueva', () {
      final AuthUser manager = user('Gerente');
      expect(manager.can(Perm.inventoryRead), isTrue);
      expect(manager.can(Perm.inventoryManage), isFalse);
    });

    test('el ingeniero sigue corrigiendo el avance que no levanta', () {
      final AuthUser engineer = user('Ingeniero');
      expect(engineer.can(Perm.progressRead), isTrue);
      expect(engineer.can(Perm.progressUpdate), isTrue);
      expect(engineer.can(Perm.progressCreate), isFalse);
    });
  });

  group('AuthUser · serialización', () {
    test('fromJson lee la respuesta de /login', () {
      final AuthUser parsed = AuthUser.fromJson(<String, dynamic>{
        'id': 'a1b2',
        'name': 'Andrés Pérez',
        'email': 'andres@xyz.com',
        'role': 'Administrador',
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
      final AuthUser original = user('Ingeniero');
      expect(AuthUser.fromJson(original.toJson()), original);
      expect(
        AuthUser.fromJson(original.toJson()).can(Perm.budgetsRead),
        isTrue,
      );
    });

    test('un permissions que llegue todavía en el JSON se ignora', () {
      final AuthUser parsed = AuthUser.fromJson(<String, dynamic>{
        'role': 'Supervisor',
        'permissions': <String>['*'],
      });

      expect(
        parsed.isAdmin,
        isFalse,
        reason: 'manda el cargo; si no, bastaría con falsear la respuesta',
      );
      expect(parsed.can(Perm.invoicesRead), isFalse);
    });
  });

  group('AuthUser · iniciales', () {
    test('toma dos iniciales de nombre y apellido', () {
      expect(user('Ingeniero').initials, 'MG');
    });

    test('con un solo nombre toma una inicial', () {
      final AuthUser single = AuthUser(
        id: '1',
        name: 'Andrés',
        email: 'a@b.com',
        role: 'Gerente',
      );
      expect(single.initials, 'A');
    });

    test('sin nombre devuelve un interrogante', () {
      final AuthUser anon = AuthUser(
        id: '1',
        name: '   ',
        email: 'a@b.com',
        role: '',
      );
      expect(anon.initials, '?');
    });
  });

  group('Session · JWT', () {
    test('lee la expiración del claim exp', () {
      final DateTime exp = DateTime.utc(2026, 12, 31, 10);
      final Session session = Session(
        token: fakeJwt(expiresAt: exp),
        user: user('Ingeniero'),
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
        user: user('Ingeniero'),
      );
      expect(session.isExpired, isTrue);
    });

    test('considera expirado un token que muere en menos de un minuto', () {
      final Session session = Session(
        token: fakeJwt(
          expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 20)),
        ),
        user: user('Ingeniero'),
      );
      expect(session.isExpired, isTrue);
    });

    test('expone el company_id del token', () {
      final Session session = Session(
        token: fakeJwt(companyId: '6f3e-empresa'),
        user: user('Ingeniero'),
      );
      expect(session.companyId, '6f3e-empresa');
    });

    test('un token malformado devuelve null en los claims y no expira', () {
      final Session session = Session(
        token: 'esto-no-es-un-jwt',
        user: user('Ingeniero'),
      );
      expect(session.expiresAt, isNull);
      expect(session.companyId, isNull);
      expect(session.isExpired, isFalse);
    });
  });
}
