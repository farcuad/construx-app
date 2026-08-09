import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';

/// Indicadores financieros consolidados de un proyecto
/// (`GET /dashboard/financial/{project_id}`).
@immutable
class ProjectKpis {
  const ProjectKpis({
    required this.projectId,
    required this.totalBudget,
    required this.totalExpenses,
    required this.totalPurchased,
    required this.totalInvoiced,
    required this.totalCollected,
    required this.totalPaidToProviders,
    required this.financialVariance,
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
  bool get isOverBudget => totalBudget > 0 &&
      (totalExpenses + totalPurchased) > totalBudget;

  factory ProjectKpis.fromJson(Map<String, dynamic> json) => ProjectKpis(
    projectId: json['project_id'] as String? ?? '',
    totalBudget: Fmt.parseNum(json['total_budget']) ?? 0,
    totalExpenses: Fmt.parseNum(json['total_expenses']) ?? 0,
    totalPurchased: Fmt.parseNum(json['total_purchased']) ?? 0,
    totalInvoiced: Fmt.parseNum(json['total_invoiced']) ?? 0,
    totalCollected: Fmt.parseNum(json['total_collected']) ?? 0,
    totalPaidToProviders: Fmt.parseNum(json['total_paid_to_prov']) ?? 0,
    financialVariance: Fmt.parseNum(json['financial_variance']) ?? 0,
  );
}
