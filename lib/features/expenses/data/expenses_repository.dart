import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../domain/expense.dart';

/// Gastos por proyecto (`/expenses`).
class ExpensesRepository {
  const ExpensesRepository(this._api);

  final ApiClient _api;

  /// `GET /expenses/{project_id}`.
  Future<List<Expense>> fetchByProject(String projectId) async =>
      (await _api.getList(
        '/expenses/$projectId',
      )).map(Expense.fromJson).toList(growable: false);

  /// `POST /expenses`.
  Future<Expense> create(Expense expense) async => Expense.fromJson(
    await _api.post('/expenses', body: expense.toRequestBody()),
  );

  /// `PUT /expenses/{id}` — todos los campos son opcionales; solo se envían
  /// los indicados para no borrar el resto.
  Future<Expense> update(
    String id, {
    String? title,
    double? amount,
    DateTime? expenseDate,
    String? description,
    int? categoryId,
  }) async => Expense.fromJson(
    await _api.put(
      '/expenses/$id',
      body: <String, dynamic>{
        'title': ?title,
        'amount': ?amount,
        if (expenseDate != null) 'expense_date': Fmt.apiDate(expenseDate),
        'description': ?description,
        'category_id': ?categoryId,
      },
    ),
  );

  /// `DELETE /expenses/{id}`.
  Future<void> delete(String id) => _api.delete('/expenses/$id');
}
