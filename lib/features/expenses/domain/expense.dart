import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Gasto imputado a un proyecto (`/expenses`).
@immutable
class Expense {
  const Expense({
    required this.id,
    required this.projectId,
    required this.title,
    required this.amount,
    this.categoryId,
    this.expenseDate,
    this.description = '',
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String title;
  final double amount;
  final int? categoryId;

  /// Campo solo-fecha (`YYYY-MM-DD`) en la API.
  final DateTime? expenseDate;
  final String description;
  final DateTime? createdAt;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: J.str(json['id']),
    projectId: J.str(json['project_id']),
    title: J.str(json['title']),
    amount: J.dbl(json['amount']),
    categoryId: J.intOrNull(json['category_id']),
    expenseDate: Fmt.parseDate(json['expense_date']),
    description: J.str(json['description']),
    createdAt: Fmt.parseDate(json['created_at']),
  );

  /// Cuerpo de `POST /expenses`. `company_id`/`user_id` los pone el backend
  /// desde el token, así que no se envían.
  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'project_id': projectId,
    'category_id': ?categoryId,
    'title': title,
    'amount': amount,
    if (expenseDate != null) 'expense_date': Fmt.apiDate(expenseDate!),
    'description': description,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Expense && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
