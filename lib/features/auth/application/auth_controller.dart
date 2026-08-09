import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';
import '../domain/session.dart';

/// Fase del ciclo de vida de la sesión.
enum AuthStatus {
  /// Restaurando la sesión guardada al arrancar la app.
  restoring,

  /// No hay sesión: hay que mostrar el login.
  unauthenticated,

  /// Sesión válida.
  authenticated,
}

/// Estado observable de la autenticación.
@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// Estado inicial: aún no sabemos si hay sesión guardada.
  const AuthState.restoring() : this(status: AuthStatus.restoring);

  final AuthStatus status;
  final Session? session;

  /// `true` mientras la petición de login está en vuelo.
  final bool isSubmitting;

  /// Mensaje de error del último intento de login, si lo hubo.
  final String? errorMessage;

  AuthUser? get user => session?.user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isRestoring => status == AuthStatus.restoring;

  /// Atajo de permisos: `false` si no hay sesión.
  bool can(String permission) => session?.user.can(permission) ?? false;

  AuthState copyWith({
    AuthStatus? status,
    Session? session,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool clearSession = false,
  }) => AuthState(
    status: status ?? this.status,
    session: clearSession ? null : (session ?? this.session),
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          other.status == status &&
          other.session == session &&
          other.isSubmitting == isSubmitting &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, session, isSubmitting, errorMessage);
}

/// Orquesta login, logout y restauración de sesión.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Cierra la sesión automáticamente si cualquier petición recibe un 401.
    ref.listen<int>(sessionExpiredSignalProvider, (int? previous, int next) {
      if (previous != null && next > previous && state.isAuthenticated) {
        logout(reason: 'Tu sesión expiró. Inicia sesión de nuevo.');
      }
    });
    return const AuthState.restoring();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Restaura la sesión persistida. Se llama una vez al arrancar la app.
  Future<void> restore() async {
    final Session? session = await _repository.restoreSession();
    if (session == null) {
      _applyToken(null);
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    _applyToken(session.token);
    state = AuthState(status: AuthStatus.authenticated, session: session);
  }

  /// Credenciales guardadas por «Recordar datos», para prerrellenar el login.
  Future<RememberedCredentials?> rememberedCredentials() =>
      _repository.rememberedCredentials();

  /// Intenta iniciar sesión. Devuelve `true` si tuvo éxito.
  ///
  /// Los errores no se propagan: se exponen en [AuthState.errorMessage] para
  /// que la vista los pinte sin necesitar un `try/catch`.
  Future<bool> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final Session session = await _repository.login(
        email: email.trim(),
        password: password,
        rememberMe: rememberMe,
      );
      _applyToken(session.token);
      state = AuthState(status: AuthStatus.authenticated, session: session);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
        errorMessage: e.message,
      );
      return false;
    } on ParseSessionException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
        errorMessage: e.message,
      );
      return false;
    } on Object {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
        errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      );
      return false;
    }
  }

  /// Cierra la sesión. Conserva las credenciales recordadas salvo que
  /// [forgetCredentials] sea `true`.
  Future<void> logout({String? reason, bool forgetCredentials = false}) async {
    await _repository.clearSession();
    if (forgetCredentials) {
      await _repository.setRememberedCredentials(null);
    }
    _applyToken(null);
    state = AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: reason,
    );
  }

  /// Limpia el error mostrado en el formulario.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void _applyToken(String? token) {
    ref.read(authTokenProvider.notifier).state = token;
  }
}

/// Estado global de autenticación.
final NotifierProvider<AuthController, AuthState> authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Usuario actual (o `null`). Provider derivado para que los widgets que solo
/// necesitan el usuario no se reconstruyan al cambiar `isSubmitting`.
final Provider<AuthUser?> currentUserProvider = Provider<AuthUser?>(
  (Ref ref) => ref.watch(authControllerProvider.select((AuthState s) => s.user)),
);
