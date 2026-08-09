import '../../../core/network/api_client.dart';
import '../domain/budget.dart';

/// Presupuestos por proyecto (`/budgets`).
class BudgetsRepository {
  const BudgetsRepository(this._api);

  final ApiClient _api;

  /// `GET /budgets/{project_id}`.
  Future<List<Budget>> fetchByProject(String projectId) async =>
      (await _api.getList(
        '/budgets/$projectId',
      )).map(Budget.fromJson).toList(growable: false);

  /// `POST /budgets` — crea el presupuesto junto con sus partidas.
  Future<Budget> create(Budget budget) async => Budget.fromJson(
    await _api.post('/budgets', body: budget.toRequestBody()),
  );

  /// `PUT /budgets/{id}` — solo título y descripción; las partidas no se
  /// editan desde este endpoint.
  Future<Budget> update(
    String id, {
    String? title,
    String? description,
  }) async => Budget.fromJson(
    await _api.put(
      '/budgets/$id',
      body: <String, dynamic>{'title': ?title, 'description': ?description},
    ),
  );

  /// `DELETE /budgets/{id}`.
  Future<void> delete(String id) => _api.delete('/budgets/$id');
}
