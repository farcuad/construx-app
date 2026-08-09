import '../../../core/network/api_client.dart';
import '../domain/supplier.dart';

/// Proveedores.
///
/// Ojo con la ruta: la API la registra en **singular** (`/supplier`), no
/// `/suppliers`.
class SuppliersRepository {
  const SuppliersRepository(this._api);

  final ApiClient _api;

  /// `GET /supplier`.
  Future<List<Supplier>> fetchAll() async => (await _api.getList(
    '/supplier',
  )).map(Supplier.fromJson).toList(growable: false);

  /// `POST /supplier`.
  Future<Supplier> create(Supplier supplier) async => Supplier.fromJson(
    await _api.post('/supplier', body: supplier.toRequestBody()),
  );

  /// `PUT /supplier/{id}`.
  Future<Supplier> update(Supplier supplier) async => Supplier.fromJson(
    await _api.put('/supplier/${supplier.id}', body: supplier.toRequestBody()),
  );

  /// `DELETE /supplier/{id}`.
  Future<void> delete(String id) => _api.delete('/supplier/$id');
}
