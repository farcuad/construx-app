import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/subscription.dart';

/// Suscripción de la empresa (`GET /subscriptions/me`).
///
/// Es la única ruta del módulo que implementa la app: solo pide un JWT normal
/// y sirve para explicarle al trabajador por qué el backend responde `402`
/// («Suscripción inactiva o expirada»). El resto de rutas de `/subscriptions`
/// exigen token de superadministrador y viven en la web, no aquí.
class SubscriptionsRepository {
  const SubscriptionsRepository(this._api);

  final ApiClient _api;

  /// `GET /subscriptions/me`.
  ///
  /// Devuelve `null` si la empresa aún no tiene suscripción (el backend
  /// responde `404`), que no es un error que deba romper la pantalla.
  Future<CompanySubscription?> fetchMine() async {
    try {
      return CompanySubscription.fromJson(
        await _api.getObject('/subscriptions/me'),
      );
    } on NotFoundException {
      return null;
    }
  }
}
