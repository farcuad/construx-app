import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_store.dart';
import '../domain/auth_user.dart';
import '../domain/session.dart';

/// Credenciales recordadas para prerrellenar el formulario de login.
@immutable
class RememberedCredentials {
  const RememberedCredentials({required this.email, required this.password});

  final String email;
  final String password;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RememberedCredentials &&
          other.email == email &&
          other.password == password;

  @override
  int get hashCode => Object.hash(email, password);
}

/// Acceso a autenticación y persistencia segura de la sesión.
///
/// La sesión (token + usuario) y las credenciales de «Recordar datos» viven en
/// el almacenamiento cifrado del sistema ([SecureStore]), nunca en
/// `SharedPreferences` ni en disco plano.
///
/// **Solo hay una puerta de entrada: `POST /login`.** Esta app es para los
/// trabajadores de la constructora; el alta de empresas (`POST /register`) y
/// el acceso del superadministrador (`POST /admin/login`) se hacen desde la
/// web y no se implementan aquí.
class AuthRepository {
  const AuthRepository(this._api, this._store);

  final ApiClient _api;
  final SecureStore _store;

  /// Autentica contra `POST /login`.
  ///
  /// Si [rememberMe] es `true`, guarda email y contraseña cifrados para
  /// prerrellenar el próximo inicio de sesión; si es `false`, borra cualquier
  /// dato recordado previamente.
  Future<Session> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/login',
      authenticated: false,
      body: <String, String>{'email': email, 'password': password},
    );

    final String token = body['token'] as String? ?? '';
    final Map<String, dynamic>? rawUser = body['user'] as Map<String, dynamic>?;
    if (token.isEmpty || rawUser == null) {
      throw const ParseSessionException();
    }

    final Session session = Session(
      token: token,
      user: AuthUser.fromJson(rawUser),
    );

    await persistSession(session);
    await setRememberedCredentials(
      rememberMe
          ? RememberedCredentials(email: email, password: password)
          : null,
    );
    return session;
  }

  /// Restaura la sesión guardada, o `null` si no hay ninguna o ya expiró.
  ///
  /// Se ejecuta en el arranque para saltar el login sin pedir credenciales.
  Future<Session?> restoreSession() async {
    final String? token = await _store.read(StorageKeys.token);
    final String? rawUser = await _store.read(StorageKeys.user);
    if (token == null || token.isEmpty || rawUser == null) return null;

    final AuthUser user;
    try {
      final Object? decoded = jsonDecode(rawUser);
      if (decoded is! Map<String, dynamic>) return null;
      user = AuthUser.fromJson(decoded);
    } on FormatException {
      await clearSession();
      return null;
    }

    final Session session = Session(token: token, user: user);
    if (session.isExpired) {
      await clearSession();
      return null;
    }
    return session;
  }

  /// Guarda token y usuario en el almacenamiento cifrado.
  Future<void> persistSession(Session session) async {
    await _store.write(StorageKeys.token, session.token);
    await _store.write(StorageKeys.user, jsonEncode(session.user.toJson()));
  }

  /// Borra la sesión. **No** toca las credenciales recordadas: cerrar sesión
  /// no debe olvidar el email que el usuario pidió recordar.
  Future<void> clearSession() async {
    await _store.delete(StorageKeys.token);
    await _store.delete(StorageKeys.user);
  }

  /// Lee las credenciales recordadas, o `null` si «Recordar datos» está
  /// desactivado o los datos están incompletos.
  Future<RememberedCredentials?> rememberedCredentials() async {
    final String? flag = await _store.read(StorageKeys.rememberMe);
    if (flag != '1') return null;
    final String? email = await _store.read(StorageKeys.rememberedEmail);
    final String? password = await _store.read(StorageKeys.rememberedPassword);
    if (email == null || email.isEmpty || password == null) return null;
    return RememberedCredentials(email: email, password: password);
  }

  /// Guarda o borra las credenciales recordadas según [credentials].
  Future<void> setRememberedCredentials(
    RememberedCredentials? credentials,
  ) async {
    if (credentials == null) {
      await _store.delete(StorageKeys.rememberMe);
      await _store.delete(StorageKeys.rememberedEmail);
      await _store.delete(StorageKeys.rememberedPassword);
      return;
    }
    await _store.write(StorageKeys.rememberMe, '1');
    await _store.write(StorageKeys.rememberedEmail, credentials.email);
    await _store.write(StorageKeys.rememberedPassword, credentials.password);
  }

  /// Borra absolutamente todo lo guardado por la app (sesión + recordados).
  Future<void> forgetEverything() => _store.deleteAll();
}

/// El backend respondió 200 pero sin `token` o sin `user`.
class ParseSessionException implements Exception {
  const ParseSessionException();

  String get message => 'El servidor no devolvió una sesión válida.';

  @override
  String toString() => 'ParseSessionException: $message';
}
