import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Material del catálogo de inventario (`/materials`).
@immutable
class InventoryMaterial {
  const InventoryMaterial({
    required this.id,
    required this.name,
    this.code = '',
    this.unit = '',
    this.categoryId,
    this.createdAt,
  });

  final String id;
  final String name;
  final String code;

  /// Unidad de medida (saco, m³, varilla…).
  final String unit;
  final String? categoryId;
  final DateTime? createdAt;

  factory InventoryMaterial.fromJson(Map<String, dynamic> json) =>
      InventoryMaterial(
        id: J.str(json['id']),
        name: J.str(json['name']),
        code: J.str(json['code']),
        unit: J.str(json['unit']),
        categoryId: J.strOrNull(json['category_id']),
        createdAt: Fmt.parseDate(json['created_at']),
      );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'name': name,
    'code': code,
    'unit': unit,
    'category_id': ?categoryId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is InventoryMaterial && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Almacén o bodega de obra (`/warehouses`).
@immutable
class Warehouse {
  const Warehouse({
    required this.id,
    required this.name,
    this.projectId,
    this.location = '',
    this.createdAt,
  });

  final String id;
  final String name;
  final String? projectId;
  final String location;
  final DateTime? createdAt;

  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
    id: J.str(json['id']),
    name: J.str(json['name']),
    projectId: J.strOrNull(json['project_id']),
    location: J.str(json['location']),
    createdAt: Fmt.parseDate(json['created_at']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'project_id': ?projectId,
    'name': name,
    'location': location,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Warehouse && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Sentido de un movimiento de stock.
enum MovementType {
  input('INPUT', 'Entrada'),
  output('OUTPUT', 'Salida');

  const MovementType(this.apiValue, this.label);

  /// Valor exacto que espera el campo `movement_type` de la API.
  final String apiValue;
  final String label;

  static MovementType fromApi(String? raw) =>
      raw == output.apiValue ? output : input;
}

/// Movimiento de existencias (`POST /inventory/movements`).
@immutable
class StockMovement {
  const StockMovement({
    required this.id,
    required this.warehouseId,
    required this.materialId,
    required this.type,
    required this.quantity,
    this.referenceId,
    this.description = '',
    this.createdAt,
  });

  final String id;
  final String warehouseId;
  final String materialId;
  final MovementType type;
  final double quantity;

  /// Documento que origina el movimiento (orden de compra, salida a obra…).
  final String? referenceId;
  final String description;
  final DateTime? createdAt;

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
    id: J.str(json['id']),
    warehouseId: J.str(json['warehouse_id']),
    materialId: J.str(json['material_id']),
    type: MovementType.fromApi(J.strOrNull(json['movement_type'])),
    quantity: J.dbl(json['quantity']),
    referenceId: J.strOrNull(json['reference_id']),
    description: J.str(json['description']),
    createdAt: Fmt.parseDate(json['created_at']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'warehouse_id': warehouseId,
    'material_id': materialId,
    'movement_type': type.apiValue,
    'quantity': quantity,
    'reference_id': ?referenceId,
    'description': description,
  };
}

/// Existencias actuales de un material en un almacén
/// (`GET /inventory/stock/{warehouse_id}`).
@immutable
class StockItem {
  const StockItem({
    required this.materialId,
    required this.materialName,
    this.code = '',
    this.unit = '',
    this.quantity = 0,
  });

  final String materialId;
  final String materialName;
  final String code;
  final String unit;
  final double quantity;

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
    materialId: J.str(json['material_id']),
    materialName: J.str(json['material_name']),
    code: J.str(json['code']),
    unit: J.str(json['unit']),
    quantity: J.dbl(json['quantity']),
  );
}
