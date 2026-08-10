import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado de red del dispositivo.
///
/// **Qué mide y qué no.** Esto observa las interfaces del teléfono (wifi,
/// datos, ethernet), no si el backend responde. Un wifi de hotel con portal
/// cautivo cuenta como «con conexión»: hay interfaz, aunque no haya internet.
/// Cubrir eso de verdad exigiría sondear el servidor cada pocos segundos, que
/// es justo el gasto de batería que esta app no quiere. El caso real de obra
/// —quedarse sin cobertura, modo avión, wifi apagado— sí lo detecta al vuelo,
/// y para lo demás sigue estando el error de la propia petición.
abstract interface class ConnectivityProbe {
  /// Emite `true` con red y `false` sin ella, empezando por el estado actual.
  Stream<bool> get onlineChanges;
}

/// Implementación real, sobre `connectivity_plus`.
class PlatformConnectivityProbe implements ConnectivityProbe {
  PlatformConnectivityProbe([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Hay red si alguna interfaz está levantada.
  ///
  /// La lista llega con varias entradas cuando el teléfono tiene wifi y datos
  /// a la vez; basta con que una sirva.
  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((ConnectivityResult r) => r != ConnectivityResult.none);

  @override
  Stream<bool> get onlineChanges async* {
    // El primer valor no lo da el stream de cambios: hay que preguntarlo.
    // Sin esto, arrancar la app ya sin cobertura no mostraría nada hasta que
    // la red cambiara de estado.
    yield _isOnline(await _connectivity.checkConnectivity());
    yield* _connectivity.onConnectivityChanged
        .map(_isOnline)
        .distinct(); // pasar de wifi a datos no es «volver a tener red»
  }
}

/// Sonda de conectividad. Los tests la sustituyen por una de mentira.
final Provider<ConnectivityProbe> connectivityProbeProvider =
    Provider<ConnectivityProbe>((Ref ref) => PlatformConnectivityProbe());

/// Estado de la red, en crudo.
final StreamProvider<bool> connectivityProvider = StreamProvider<bool>(
  (Ref ref) => ref.watch(connectivityProbeProvider).onlineChanges,
);

/// `true` solo cuando consta que **no** hay red.
///
/// Mientras la primera lectura está en vuelo se asume que sí la hay: es mejor
/// dejar entrar a la app y que falle una petición, que tapar la pantalla medio
/// segundo en cada arranque.
final Provider<bool> isOfflineProvider = Provider<bool>(
  (Ref ref) => ref.watch(connectivityProvider).valueOrNull == false,
);
