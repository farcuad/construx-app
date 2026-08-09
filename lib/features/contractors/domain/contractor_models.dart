import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Empresa contratista (`/contractors`).
@immutable
class Contractor {
  const Contractor({
    required this.id,
    required this.name,
    this.nit = '',
    this.representative = '',
    this.phone = '',
    this.email = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String nit;

  /// Representante legal.
  final String representative;
  final String phone;
  final String email;
  final bool isActive;

  factory Contractor.fromJson(Map<String, dynamic> json) => Contractor(
    id: J.str(json['id']),
    name: J.str(json['name']),
    nit: J.str(json['nit']),
    representative: J.str(json['representative']),
    phone: J.str(json['phone']),
    email: J.str(json['email']),
    isActive: J.boolOf(json['is_active'], fallback: true),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'name': name,
    'nit': nit,
    'representative': representative,
    'phone': phone,
    'email': email,
    'is_active': isActive,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Contractor && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Estados de un contrato con contratista.
abstract final class ContractorContractStatus {
  static const String active = 'Active';
  static const String finished = 'Finished';
  static const String cancelled = 'Cancelled';
}

/// Contrato con un contratista para un proyecto
/// (`/contractors/contracts`).
@immutable
class ContractorContract {
  const ContractorContract({
    required this.id,
    required this.contractorId,
    required this.projectId,
    required this.title,
    this.totalAmount = 0,
    this.balance = 0,
    this.startDate,
    this.endDate,
    this.status = ContractorContractStatus.active,
  });

  final String id;
  final String contractorId;
  final String projectId;
  final String title;
  final double totalAmount;

  /// Saldo pendiente. El backend lo inicializa igual a [totalAmount] y lo va
  /// descontando con cada pago registrado.
  final double balance;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  /// Proporción ya pagada del contrato (0..1).
  double? get paidRatio {
    if (totalAmount <= 0) return null;
    return ((totalAmount - balance) / totalAmount).clamp(0.0, 1.0);
  }

  factory ContractorContract.fromJson(Map<String, dynamic> json) =>
      ContractorContract(
        id: J.str(json['id']),
        contractorId: J.str(json['contractor_id']),
        projectId: J.str(json['project_id']),
        title: J.str(json['title']),
        totalAmount: J.dbl(json['total_amount']),
        balance: J.dbl(json['balance']),
        startDate: Fmt.parseDate(json['start_date']),
        endDate: Fmt.parseDate(json['end_date']),
        status: J.str(json['status']),
      );

  /// Cuerpo de `POST /contractors/contracts`.
  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'contractor_id': contractorId,
    'project_id': projectId,
    'title': title,
    'total_amount': totalAmount,
    if (startDate != null) 'start_date': Fmt.apiDate(startDate!),
    if (endDate != null) 'end_date': Fmt.apiDate(endDate!),
    'status': status,
  };

  /// Cuerpo de `PUT /contractors/contracts/{id}`, que además admite `balance`.
  Map<String, dynamic> toUpdateBody() => <String, dynamic>{
    'title': title,
    'total_amount': totalAmount,
    'balance': balance,
    if (startDate != null) 'start_date': Fmt.apiDate(startDate!),
    if (endDate != null) 'end_date': Fmt.apiDate(endDate!),
    'status': status,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ContractorContract && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Pago a cuenta de un contrato con contratista
/// (`/contractors/payments`).
@immutable
class ContractorPayment {
  const ContractorPayment({
    required this.id,
    required this.contractId,
    required this.amount,
    this.paymentDate,
    this.referenceNumber = '',
    this.notes = '',
  });

  final String id;
  final String contractId;
  final double amount;

  /// Campo solo-fecha (`YYYY-MM-DD`).
  final DateTime? paymentDate;
  final String referenceNumber;
  final String notes;

  factory ContractorPayment.fromJson(Map<String, dynamic> json) =>
      ContractorPayment(
        id: J.str(json['id']),
        contractId: J.str(json['contract_id']),
        amount: J.dbl(json['amount']),
        paymentDate: Fmt.parseDate(json['payment_date']),
        referenceNumber: J.str(json['reference_number']),
        notes: J.str(json['notes']),
      );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'contract_id': contractId,
    'amount': amount,
    if (paymentDate != null) 'payment_date': Fmt.apiDate(paymentDate!),
    'reference_number': referenceNumber,
    'notes': notes,
  };
}
