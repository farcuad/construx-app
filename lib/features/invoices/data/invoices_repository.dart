import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../domain/invoice_models.dart';

/// Facturación y cobros/pagos (`/invoices`).
class InvoicesRepository {
  const InvoicesRepository(this._api);

  final ApiClient _api;

  /// `GET /invoices/project/{project_id}`.
  Future<List<Invoice>> fetchByProject(String projectId) async =>
      (await _api.getList(
        '/invoices/project/$projectId',
      )).map(Invoice.fromJson).toList(growable: false);

  /// `GET /invoices/{id}` — la factura con sus líneas y sus pagos.
  Future<Invoice> fetchById(String id) async =>
      Invoice.fromJson(await _api.getObject('/invoices/$id'));

  /// `POST /invoices`.
  Future<Invoice> create(Invoice invoice) async => Invoice.fromJson(
    await _api.post('/invoices', body: invoice.toRequestBody()),
  );

  /// `PUT /invoices/{id}` — responde solo con un mensaje.
  Future<void> update(
    String id, {
    String? status,
    String? notes,
    DateTime? dueDate,
  }) => _api.put(
    '/invoices/$id',
    body: <String, dynamic>{
      'status': ?status,
      'notes': ?notes,
      if (dueDate != null) 'due_date': Fmt.apiDate(dueDate),
    },
  );

  /// `PATCH /invoices/{id}/cancel` — anula la factura.
  Future<void> cancel(String id) => _api.patch('/invoices/$id/cancel');

  /// `DELETE /invoices/{id}`.
  Future<void> delete(String id) => _api.delete('/invoices/$id');

  /// `GET /invoices/payments/{invoice_id}`.
  Future<List<Payment>> fetchPayments(String invoiceId) async =>
      (await _api.getList(
        '/invoices/payments/$invoiceId',
      )).map(Payment.fromJson).toList(growable: false);

  /// `POST /invoices/payments` — registra un cobro o un pago.
  Future<Payment> registerPayment(Payment payment) async => Payment.fromJson(
    await _api.post('/invoices/payments', body: payment.toRequestBody()),
  );
}
