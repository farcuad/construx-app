import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../domain/purchase_order.dart';

/// Órdenes de compra.
///
/// La ruta es `/purcharse` (sic): es un error tipográfico histórico del
/// backend y cambiarlo aquí rompería las llamadas.
class PurchasesRepository {
  const PurchasesRepository(this._api);

  final ApiClient _api;

  /// `GET /purcharse/{project_id}`.
  Future<List<PurchaseOrder>> fetchByProject(String projectId) async =>
      (await _api.getList(
        '/purcharse/$projectId',
      )).map(PurchaseOrder.fromJson).toList(growable: false);

  /// `POST /purcharse` — crea la orden con sus líneas.
  Future<PurchaseOrder> create(PurchaseOrder order) async =>
      PurchaseOrder.fromJson(
        await _api.post('/purcharse', body: order.toRequestBody()),
      );

  /// `PUT /purcharse/{id}` — solo estado, fecha de entrega y notas.
  Future<PurchaseOrder> update(
    String id, {
    String? status,
    DateTime? deliveryDate,
    String? notes,
  }) async => PurchaseOrder.fromJson(
    await _api.put(
      '/purcharse/$id',
      body: <String, dynamic>{
        'status': ?status,
        if (deliveryDate != null) 'delivery_date': Fmt.apiDate(deliveryDate),
        'notes': ?notes,
      },
    ),
  );

  /// Atajo de [update] para aprobar una orden.
  Future<PurchaseOrder> approve(String id) =>
      update(id, status: PurchaseStatus.approved);

  /// `DELETE /purcharse/{id}`.
  Future<void> delete(String id) => _api.delete('/purcharse/$id');
}
