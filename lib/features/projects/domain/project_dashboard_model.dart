import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';

/// Un punto de la tendencia mensual (`monthly_trends`).
///
/// Cada mes compara lo facturado, lo cobrado y lo gastado, que es lo que
/// dibuja el gráfico principal del panel.
@immutable
class MonthlyTrend {
  const MonthlyTrend({
    required this.month,
    required this.invoiced,
    required this.collected,
    required this.expenses,
  });

  /// Etiqueta corta del mes tal y como la manda la API («Mar», «Ago»…).
  final String month;
  final double invoiced;
  final double collected;
  final double expenses;

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) => MonthlyTrend(
    month: json['month'] as String? ?? '',
    invoiced: Fmt.parseNum(json['invoiced']) ?? 0,
    collected: Fmt.parseNum(json['collected']) ?? 0,
    expenses: Fmt.parseNum(json['expenses']) ?? 0,
  );
}

/// Gasto acumulado en una categoría (`expenses_by_category`).
@immutable
class CategoryExpense {
  const CategoryExpense({required this.category, required this.spent});

  final String category;
  final double spent;

  factory CategoryExpense.fromJson(Map<String, dynamic> json) =>
      CategoryExpense(
        category: json['category'] as String? ?? '—',
        spent: Fmt.parseNum(json['spent']) ?? 0,
      );
}

/// Dashboard financiero de un proyecto
/// (`GET /dashboard/financial/{project_id}`).
///
/// Además de las siete cifras históricas, lleva la **tendencia mensual**
/// (`monthly_trends`) y el **desglose por categoría** (`expenses_by_category`)
/// que alimentan los gráficos del panel.
@immutable
class ProjectDashboardModel {
  const ProjectDashboardModel({
    required this.projectId,
    required this.totalBudget,
    required this.totalExpenses,
    required this.totalPurchased,
    required this.totalInvoiced,
    required this.totalCollected,
    required this.totalPaidToProviders,
    required this.financialVariance,
    this.monthlyTrends = const <MonthlyTrend>[],
    this.expensesByCategory = const <CategoryExpense>[],
  });

  final String projectId;
  final double totalBudget;
  final double totalExpenses;
  final double totalPurchased;
  final double totalInvoiced;
  final double totalCollected;
  final double totalPaidToProviders;

  /// Diferencia entre lo presupuestado y lo comprometido, según el backend.
  final double financialVariance;

  /// Serie mensual de facturado / cobrado / gastos.
  final List<MonthlyTrend> monthlyTrends;

  /// Gasto acumulado por categoría para la gráfica de dona.
  final List<CategoryExpense> expensesByCategory;

  /// Gasto comprometido total (gastos + compras).
  double get totalSpent => totalExpenses + totalPurchased;

  /// Porcentaje del presupuesto ya consumido (gastos + compras), 0..100.
  ///
  /// Devuelve `null` si no hay presupuesto con el que comparar.
  double? get budgetUsedPercent {
    if (totalBudget <= 0) return null;
    return ((totalExpenses + totalPurchased) / totalBudget * 100).clamp(
      0.0,
      999.0,
    );
  }

  /// `true` si el gasto comprometido supera el presupuesto.
  bool get isOverBudget =>
      totalBudget > 0 && (totalExpenses + totalPurchased) > totalBudget;

  /// Distribución de gastos para la gráfica de dona.
  ///
  /// Usa el desglose de la API y, si no llega o llega vacío, cae a una reparto
  /// por defecto calculado sobre los datos generales del proyecto.
  List<CategoryExpense> get categoryBreakdown {
    if (expensesByCategory.isNotEmpty) return expensesByCategory;
    return _defaultDistribution;
  }

  /// Reparto por rubros típicos de obra cuando la API no envía categorías.
  List<CategoryExpense> get _defaultDistribution {
    const List<(String, double)> weights = <(String, double)>[
      ('Materiales', 0.60),
      ('Personal', 0.25),
      ('Equipos', 0.15),
    ];
    return <CategoryExpense>[
      for (final (String name, double weight) in weights)
        CategoryExpense(category: name, spent: totalSpent * weight),
    ];
  }

  factory ProjectDashboardModel.fromJson(Map<String, dynamic> json) =>
      ProjectDashboardModel(
        projectId: json['project_id'] as String? ?? '',
        totalBudget: Fmt.parseNum(json['total_budget']) ?? 0,
        totalExpenses: Fmt.parseNum(json['total_expenses']) ?? 0,
        totalPurchased: Fmt.parseNum(json['total_purchased']) ?? 0,
        totalInvoiced: Fmt.parseNum(json['total_invoiced']) ?? 0,
        totalCollected: Fmt.parseNum(json['total_collected']) ?? 0,
        totalPaidToProviders: Fmt.parseNum(json['total_paid_to_prov']) ?? 0,
        financialVariance: Fmt.parseNum(json['financial_variance']) ?? 0,
        monthlyTrends: _parseList(json['monthly_trends'], MonthlyTrend.fromJson),
        expensesByCategory: _parseList(
          json['expenses_by_category'],
          CategoryExpense.fromJson,
        ),
      );

  static List<T> _parseList<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return <T>[];
    return <T>[
      for (final Object? item in raw)
        if (item is Map<String, dynamic>) fromJson(item),
    ];
  }
}