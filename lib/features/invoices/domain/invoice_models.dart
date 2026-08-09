import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Sentido de la factura.
enum InvoiceType {
  /// Emitida al cliente: genera cobros.
  emitted('EMITTED', 'Emitida'),

  /// Recibida de un proveedor o contratista: genera pagos.
  received('RECEIVED', 'Recibida');

  const InvoiceType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static InvoiceType fromApi(String? raw) =>
      raw == received.apiValue ? received : emitted;
}

/// Estados de factura que usa el backend.
abstract final class InvoiceStatus {
  static const String draft = 'Draft';
  static const String issued = 'Issued';
  static const String paid = 'Paid';
  static const String cancelled = 'Cancelled';
}

/// Línea de factura.
@immutable
class InvoiceItem {
  const InvoiceItem({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
    this.reportedTotal,
  });

  final String description;
  final double quantity;
  final double unitPrice;

  /// Importe tal y como lo manda el backend, si lo manda.
  final double? reportedTotal;

  /// Importe de la línea: el del backend o, si falta, el calculado.
  double get total => reportedTotal ?? quantity * unitPrice;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
    description: J.str(json['description']),
    quantity: J.dbl(json['quantity'], 1),
    unitPrice: J.dbl(json['unit_price']),
    reportedTotal: J.dblOrNull(json['total']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'description': description,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total': total,
  };
}

/// Pago aplicado a una factura (`/invoices/payments`).
@immutable
class Payment {
  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    this.projectId,
    this.paymentDate,
    this.paymentMethod = '',
    this.reference = '',
    this.notes = '',
  });

  final String id;
  final String invoiceId;
  final String? projectId;
  final double amount;

  /// Campo solo-fecha (`YYYY-MM-DD`).
  final DateTime? paymentDate;
  final String paymentMethod;
  final String reference;
  final String notes;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: J.str(json['id']),
    invoiceId: J.str(json['invoice_id']),
    projectId: J.strOrNull(json['project_id']),
    amount: J.dbl(json['amount']),
    paymentDate: Fmt.parseDate(json['payment_date']),
    paymentMethod: J.str(json['payment_method']),
    reference: J.str(json['reference']),
    notes: J.str(json['notes']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'invoice_id': invoiceId,
    'project_id': ?projectId,
    if (paymentDate != null) 'payment_date': Fmt.apiDate(paymentDate!),
    'amount': amount,
    'payment_method': paymentMethod,
    'reference': reference,
    'notes': notes,
  };
}

/// Factura emitida o recibida (`/invoices`).
@immutable
class Invoice {
  const Invoice({
    required this.id,
    required this.projectId,
    required this.invoiceNumber,
    this.type = InvoiceType.emitted,
    this.status = InvoiceStatus.draft,
    this.clientId,
    this.supplierId,
    this.contractorId,
    this.issueDate,
    this.dueDate,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.reportedRemaining,
    this.notes = '',
    this.items = const <InvoiceItem>[],
    this.payments = const <Payment>[],
  });

  final String id;
  final String projectId;
  final String invoiceNumber;
  final InvoiceType type;
  final String status;

  /// Contraparte: solo uno de los tres viene informado.
  final String? clientId;
  final String? supplierId;
  final String? contractorId;

  /// Campos solo-fecha (`YYYY-MM-DD`).
  final DateTime? issueDate;
  final DateTime? dueDate;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;

  /// Saldo tal y como lo manda el backend (`remaining_amount`), si lo manda.
  final double? reportedRemaining;
  final String notes;
  final List<InvoiceItem> items;
  final List<Payment> payments;

  /// Saldo pendiente: el que da el backend o, si no viene, el total menos lo
  /// ya pagado.
  double get remainingAmount =>
      reportedRemaining ??
      totalAmount -
          payments.fold<double>(0, (double s, Payment p) => s + p.amount);

  bool get isPaid => remainingAmount <= 0;

  bool get isCancelled => status == InvoiceStatus.cancelled;

  /// `true` si venció y sigue con saldo.
  bool get isOverdue {
    final DateTime? due = dueDate;
    if (due == null || isPaid || isCancelled) return false;
    return due.isBefore(DateTime.now());
  }

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: J.str(json['id']),
    projectId: J.str(json['project_id']),
    invoiceNumber: J.str(json['invoice_number']),
    type: InvoiceType.fromApi(J.strOrNull(json['type'])),
    status: J.str(json['status']),
    clientId: J.strOrNull(json['client_id']),
    supplierId: J.strOrNull(json['supplier_id']),
    contractorId: J.strOrNull(json['contractor_id']),
    issueDate: Fmt.parseDate(json['issue_date']),
    dueDate: Fmt.parseDate(json['due_date']),
    subtotal: J.dbl(json['subtotal']),
    taxAmount: J.dbl(json['tax_amount']),
    totalAmount: J.dbl(json['total_amount']),
    reportedRemaining: J.dblOrNull(json['remaining_amount']),
    notes: J.str(json['notes']),
    items: J.list(json['items'], InvoiceItem.fromJson),
    payments: J.list(json['payments'], Payment.fromJson),
  );

  /// Cuerpo de `POST /invoices`.
  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'project_id': projectId,
    'invoice_number': invoiceNumber,
    'type': type.apiValue,
    'status': status,
    'client_id': ?clientId,
    'supplier_id': ?supplierId,
    'contractor_id': ?contractorId,
    if (issueDate != null) 'issue_date': Fmt.apiDate(issueDate!),
    if (dueDate != null) 'due_date': Fmt.apiDate(dueDate!),
    'subtotal': subtotal,
    'tax_amount': taxAmount,
    'total_amount': totalAmount,
    'notes': notes,
    'items': items
        .map((InvoiceItem i) => i.toRequestBody())
        .toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Invoice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
