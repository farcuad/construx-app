import '../../../core/network/api_client.dart';
import '../domain/contractor_models.dart';

/// Contratistas, sus contratos y los pagos que se les hacen.
class ContractorsRepository {
  const ContractorsRepository(this._api);

  final ApiClient _api;

  // ── Contratistas ────────────────────────────────────────────────────────

  /// `GET /contractors`.
  Future<List<Contractor>> fetchAll() async => (await _api.getList(
    '/contractors',
  )).map(Contractor.fromJson).toList(growable: false);

  /// `POST /contractors`.
  Future<Contractor> create(Contractor contractor) async => Contractor.fromJson(
    await _api.post('/contractors', body: contractor.toRequestBody()),
  );

  /// `PUT /contractors/{id}`.
  Future<Contractor> update(Contractor contractor) async => Contractor.fromJson(
    await _api.put(
      '/contractors/${contractor.id}',
      body: contractor.toRequestBody(),
    ),
  );

  /// `DELETE /contractors/{id}` → `204`.
  Future<void> delete(String id) => _api.delete('/contractors/$id');

  // ── Contratos ───────────────────────────────────────────────────────────

  /// `GET /contractors/contracts/{project_id}`.
  Future<List<ContractorContract>> fetchContracts(String projectId) async =>
      (await _api.getList(
        '/contractors/contracts/$projectId',
      )).map(ContractorContract.fromJson).toList(growable: false);

  /// `POST /contractors/contracts` — el saldo arranca igual al total.
  Future<ContractorContract> createContract(
    ContractorContract contract,
  ) async => ContractorContract.fromJson(
    await _api.post('/contractors/contracts', body: contract.toRequestBody()),
  );

  /// `PUT /contractors/contracts/{id}`.
  Future<ContractorContract> updateContract(
    ContractorContract contract,
  ) async => ContractorContract.fromJson(
    await _api.put(
      '/contractors/contracts/${contract.id}',
      body: contract.toUpdateBody(),
    ),
  );

  /// `DELETE /contractors/contracts/{id}` → `204`.
  Future<void> deleteContract(String id) =>
      _api.delete('/contractors/contracts/$id');

  // ── Pagos ───────────────────────────────────────────────────────────────

  /// `GET /contractors/payments` — pagos de toda la empresa.
  Future<List<ContractorPayment>> fetchPayments() async => (await _api.getList(
    '/contractors/payments',
  )).map(ContractorPayment.fromJson).toList(growable: false);

  /// `POST /contractors/payments` — descuenta del saldo del contrato.
  Future<ContractorPayment> registerPayment(ContractorPayment payment) async =>
      ContractorPayment.fromJson(
        await _api.post('/contractors/payments', body: payment.toRequestBody()),
      );
}
