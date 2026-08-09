import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_constructora/core/storage/secure_store.dart';

void main() {
  group('InMemorySecureStore', () {
    late InMemorySecureStore store;

    setUp(() => store = InMemorySecureStore());

    test('escribe y lee un valor', () async {
      await store.write(StorageKeys.token, 'jwt-123');
      expect(await store.read(StorageKeys.token), 'jwt-123');
    });

    test('devuelve null para claves inexistentes', () async {
      expect(await store.read('inexistente'), isNull);
    });

    test('sobreescribe el valor de una clave existente', () async {
      await store.write(StorageKeys.token, 'viejo');
      await store.write(StorageKeys.token, 'nuevo');
      expect(await store.read(StorageKeys.token), 'nuevo');
    });

    test('borra una clave concreta sin tocar las demás', () async {
      await store.write(StorageKeys.token, 'jwt');
      await store.write(StorageKeys.rememberedEmail, 'a@b.com');

      await store.delete(StorageKeys.token);

      expect(await store.read(StorageKeys.token), isNull);
      expect(await store.read(StorageKeys.rememberedEmail), 'a@b.com');
    });

    test('deleteAll vacía el almacén', () async {
      await store.write(StorageKeys.token, 'jwt');
      await store.write(StorageKeys.user, '{}');

      await store.deleteAll();

      expect(store.snapshot, isEmpty);
    });

    test('se puede sembrar con datos iniciales', () async {
      final InMemorySecureStore seeded = InMemorySecureStore(
        <String, String>{StorageKeys.rememberMe: '1'},
      );
      expect(await seeded.read(StorageKeys.rememberMe), '1');
    });

    test('las claves de almacenamiento son distintas entre sí', () {
      final Set<String> keys = <String>{
        StorageKeys.token,
        StorageKeys.user,
        StorageKeys.rememberMe,
        StorageKeys.rememberedEmail,
        StorageKeys.rememberedPassword,
      };
      expect(keys, hasLength(5));
    });
  });
}
