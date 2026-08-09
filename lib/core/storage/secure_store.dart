import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Claves usadas en el almacenamiento seguro. Centralizadas para evitar
/// literales sueltos repartidos por la app.
abstract final class StorageKeys {
  /// JWT de la sesión activa.
  static const String token = 'auth.token';

  /// Usuario serializado (id, nombre, email, rol, permisos).
  static const String user = 'auth.user';

  /// `'1'` si el usuario marcó «Recordar datos».
  static const String rememberMe = 'auth.remember_me';

  /// Email recordado.
  static const String rememberedEmail = 'auth.remembered_email';

  /// Contraseña recordada (cifrada por el keystore/keychain del sistema).
  static const String rememberedPassword = 'auth.remembered_password';
}

/// Abstracción sobre el almacenamiento cifrado del dispositivo.
///
/// Es el equivalente en Flutter a `SecureStore` de React Native: los valores se
/// guardan en el **Android Keystore** (`EncryptedSharedPreferences`) y en el
/// **Keychain** de iOS, no en texto plano.
///
/// Se define como interfaz para poder inyectar [InMemorySecureStore] en los
/// tests sin depender de los canales de plataforma.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Implementación real sobre `flutter_secure_storage`.
class FlutterSecureStore implements SecureStore {
  FlutterSecureStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

/// Implementación en memoria para tests y para previsualizaciones.
class InMemorySecureStore implements SecureStore {
  InMemorySecureStore([Map<String, String>? seed])
    : _data = <String, String>{...?seed};

  final Map<String, String> _data;

  /// Vista de solo lectura del contenido, útil para aserciones en tests.
  Map<String, String> get snapshot => Map<String, String>.unmodifiable(_data);

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> deleteAll() async => _data.clear();
}
