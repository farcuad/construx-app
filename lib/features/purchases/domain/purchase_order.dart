import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Línea de una orden de compra.
@immutable
class PurchaseItem {
  const PurchaseItem({
    required this.description,
    this.unit = '',
    this.quantity = 0,
    this.unitPrice = 0,
    this.reportedTotalPrice,
  });

  final String description;
  final String unit;
  final double quantity;
  final double unitPrice;

  /// Importe tal y como lo manda el backend, si lo manda.
  final double? reportedTotalPrice;

  /// Importe de la línea: el que manda el backend, o el calculado si no viene.
  double get totalPrice => reportedTotalPrice ?? quantity * unitPrice;

  factory PurchaseItem.fromJson(Map<String, dynamic> json) => PurchaseItem(
    description: J.str(json['description']),
    unit: J.str(json['unit']),
    quantity: J.dbl(json['quantity']),
    unitPrice: J.dbl(json['unit_price']),
    reportedTotalPrice: J.dblOrNull(json['total_price']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'description': description,
    'unit': unit,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
  };
}

/// Estados que maneja el backend para una orden de compra.
abstract final class PurchaseStatus {
  static const String pending = 'PENDING';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';
  static const String received = 'RECEIVED';
}

/// Orden de compra (`/purcharse` — el error tipográfico es de la API y hay
/// que respetarlo).
@immutable
class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.projectId,
    this.supplierId,
    this.status = PurchaseStatus.pending,
    this.totalAmount = 0,
    this.deliveryDate,
    this.notes = '',
    this.items = const <PurchaseItem>[],
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String? supplierId;
  final String status;
  final double totalAmount;

  /// Campo solo-fecha (`YYYY-MM-DD`).
  final DateTime? deliveryDate;
  final String notes;
  final List<PurchaseItem> items;
  final DateTime? createdAt;

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) => PurchaseOrder(
    id: J.str(json['id']),
    projectId: J.str(json['project_id']),
    supplierId: J.strOrNull(json['supplier_id']),
    status: J.str(json['status']),
    totalAmount: J.dbl(json['total_amount']),
    deliveryDate: Fmt.parseDate(json['delivery_date']),
    notes: J.str(json['notes']),
    items: J.list(json['items'], PurchaseItem.fromJson),
    createdAt: Fmt.parseDate(json['created_at']),
  );

  /// Cuerpo de `POST /purcharse`.
  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'project_id': projectId,
    'supplier_id': ?supplierId,
    'status': status,
    'total_amount': totalAmount,
    if (deliveryDate != null) 'delivery_date': Fmt.apiDate(deliveryDate!),
    'notes': notes,
    'items': items
        .map((PurchaseItem i) => i.toRequestBody())
        .toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PurchaseOrder && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
