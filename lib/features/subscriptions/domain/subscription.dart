import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Suscripción de la empresa al servicio (`/subscriptions`).
///
/// El middleware `RequireActiveSubscription` responde `402` cuando esta
/// suscripción no está activa, así que su estado explica muchos errores de la
/// app.
@immutable
class CompanySubscription {
  const CompanySubscription({
    required this.id,
    required this.status,
    this.startDate,
    this.endDate,
    this.trialEndDate,
    this.price = 0,
    this.billingCycle = '',
    this.maxProjects,
    this.maxUsers,
    this.maxStorageMb,
    this.features = const <String, dynamic>{},
    this.lastPaymentDate,
    this.nextBillingDate,
    this.cancelledAt,
  });

  final String id;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Fin del periodo de prueba que se crea al registrar la empresa.
  final DateTime? trialEndDate;
  final double price;
  final String billingCycle;

  /// Límites del plan. `POST /projects` responde `402` al superar
  /// [maxProjects].
  final int? maxProjects;
  final int? maxUsers;
  final int? maxStorageMb;
  final Map<String, dynamic> features;
  final DateTime? lastPaymentDate;
  final DateTime? nextBillingDate;
  final DateTime? cancelledAt;

  bool get isActive => status.toLowerCase() == 'active';

  /// Indica si la empresa puede entrar a los módulos protegidos del SaaS.
  ///
  /// Además del estado se comprueba la fecha: así un `trial` que todavía no
  /// haya sido actualizado por el backend se bloquea al llegar su vencimiento.
  bool get hasAccess => hasAccessAt(DateTime.now());

  @visibleForTesting
  bool hasAccessAt(DateTime now) {
    final String normalizedStatus = status.trim().toLowerCase();
    final DateTime instant = now.toUtc();

    if (cancelledAt != null && !cancelledAt!.toUtc().isAfter(instant)) {
      return false;
    }
    if (normalizedStatus == 'trial') {
      return trialEndDate?.toUtc().isAfter(instant) ?? false;
    }
    if (normalizedStatus == 'active') {
      return endDate?.toUtc().isAfter(instant) ?? true;
    }
    return false;
  }

  /// Días que faltan para que caduque, o `null` si no tiene fin.
  int? get daysRemaining {
    final DateTime? end = endDate ?? trialEndDate;
    if (end == null) return null;
    return end.difference(DateTime.now()).inDays;
  }

  factory CompanySubscription.fromJson(Map<String, dynamic> json) =>
      CompanySubscription(
        id: J.str(json['id']),
        status: J.str(json['status']),
        startDate: Fmt.parseDate(json['start_date']),
        endDate: Fmt.parseDate(json['end_date']),
        trialEndDate: Fmt.parseDate(json['trial_end_date']),
        price: J.dbl(json['price']),
        billingCycle: J.str(json['billing_cycle']),
        maxProjects: J.intOrNull(json['max_projects']),
        maxUsers: J.intOrNull(json['max_users']),
        maxStorageMb: J.intOrNull(json['max_storage_mb']),
        features: json['features'] is Map<String, dynamic>
            ? json['features'] as Map<String, dynamic>
            : const <String, dynamic>{},
        lastPaymentDate: Fmt.parseDate(json['last_payment_date']),
        nextBillingDate: Fmt.parseDate(json['next_billing_date']),
        cancelledAt: Fmt.parseDate(json['cancelled_at']),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CompanySubscription && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
