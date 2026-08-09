import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_constructora/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('acepta correos válidos', () {
      for (final String email in <String>[
        'andres@xyz.com',
        'maria.gomez+obra@constructora.co',
        'a@b.io',
      ]) {
        expect(Validators.email(email), isNull, reason: email);
      }
    });

    test('rechaza correos inválidos', () {
      for (final String email in <String>[
        'andres',
        'andres@',
        '@xyz.com',
        'andres@xyz',
        'andres xyz@mail.com',
      ]) {
        expect(Validators.email(email), isNotNull, reason: email);
      }
    });

    test('exige el campo cuando está vacío o nulo', () {
      expect(Validators.email(''), 'Ingresa tu correo electrónico');
      expect(Validators.email(null), 'Ingresa tu correo electrónico');
      expect(Validators.email('   '), 'Ingresa tu correo electrónico');
    });

    test('ignora espacios alrededor', () {
      expect(Validators.email('  andres@xyz.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('acepta contraseñas con la longitud mínima', () {
      expect(Validators.password('clave123'), isNull);
    });

    test('rechaza contraseñas cortas', () {
      expect(Validators.password('abc'), 'Debe tener al menos 6 caracteres');
    });

    test('rechaza la contraseña vacía', () {
      expect(Validators.password(''), 'Ingresa tu contraseña');
      expect(Validators.password(null), 'Ingresa tu contraseña');
    });

    test('respeta una longitud mínima personalizada', () {
      expect(Validators.password('12345678', minLength: 10), isNotNull);
    });
  });

  group('Validators.required', () {
    test('acepta texto con contenido', () {
      expect(Validators.required('Torres del Parque'), isNull);
    });

    test('rechaza vacío y solo espacios', () {
      expect(Validators.required(''), 'Campo obligatorio');
      expect(Validators.required('   '), 'Campo obligatorio');
      expect(Validators.required(null), 'Campo obligatorio');
    });

    test('usa el mensaje personalizado', () {
      expect(Validators.required('', message: 'Falta el nombre'),
          'Falta el nombre');
    });
  });

  group('Validators.amount', () {
    test('acepta enteros y decimales, con coma o punto', () {
      expect(Validators.amount('2500000'), isNull);
      expect(Validators.amount('2500.50'), isNull);
      expect(Validators.amount('2500,50'), isNull);
    });

    test('rechaza texto no numérico', () {
      expect(Validators.amount('mucho'), 'Monto inválido');
    });

    test('rechaza negativos', () {
      expect(Validators.amount('-10'), 'El monto no puede ser negativo');
    });

    test('permite vacío cuando es opcional', () {
      expect(Validators.amount('', isRequired: false), isNull);
      expect(Validators.amount('', isRequired: true), 'Ingresa un monto');
    });
  });
}
