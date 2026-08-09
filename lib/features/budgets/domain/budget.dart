import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Partida de un presupuesto.
@immutable
class BudgetItem {
  const BudgetItem({
    required this.description,
    this.category = '',
    this.unit = '',
    this.quantity = 0,
    this.unitPrice = 0,
  });

  final String description;
  final String category;
  final String unit;
  final double quantity;
  final double unitPrice;

  /// Importe de la partida. El backend suma estas líneas para el total del
  /// presupuesto; aquí se recalcula para poder mostrarlo antes de guardar.
  double get total => quantity * unitPrice;

  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
    description: J.str(json['description']),
    category: J.str(json['category']),
    unit: J.str(json['unit']),
    quantity: J.dbl(json['quantity']),
    unitPrice: J.dbl(json['unit_price']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'category': category,
    'description': description,
    'unit': unit,
    'quantity': quantity,
    'unit_price': unitPrice,
  };
}

/// Presupuesto de un proyecto (`/budgets`).
@immutable
class Budget {
  const Budget({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.totalAmount = 0,
    this.items = const <BudgetItem>[],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;

  /// Total calculado por el backend a partir de las partidas.
  final double totalAmount;
  final List<BudgetItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: J.str(json['id']),
    projectId: J.str(json['project_id']),
    title: J.str(json['title']),
    description: J.str(json['description']),
    totalAmount: J.dbl(json['total_amount']),
    items: J.list(json['items'], BudgetItem.fromJson),
    createdAt: Fmt.parseDate(json['created_at']),
    updatedAt: Fmt.parseDate(json['updated_at']),
  );

  /// Cuerpo de `POST /budgets` (crea el presupuesto con sus partidas).
  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'project_id': projectId,
    'title': title,
    'description': description,
    'items': items
        .map((BudgetItem i) => i.toRequestBody())
        .toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Budget && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
