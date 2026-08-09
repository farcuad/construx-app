import '../../../core/network/api_client.dart';
import '../domain/client.dart';

/// Acceso a los endpoints de clientes (`/clients`).
class ClientsRepository {
  const ClientsRepository(this._api);

  final ApiClient _api;

  /// `GET /clients`.
  Future<List<Client>> fetchAll() async {
    final List<Map<String, dynamic>> raw = await _api.getList('/clients');
    return raw.map(Client.fromJson).toList(growable: false);
  }

  /// `POST /clients`.
  Future<Client> create(Client client) async =>
      Client.fromJson(await _api.post('/clients', body: client.toRequestBody()));

  /// `PUT /clients/{id}`.
  Future<Client> update(Client client) async => Client.fromJson(
    await _api.put('/clients/${client.id}', body: client.toRequestBody()),
  );

  /// `DELETE /clients/{id}`.
  Future<void> delete(String id) => _api.delete('/clients/$id');
}
