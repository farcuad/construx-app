import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Categoría de maquinaria (`/equipment/types`).
@immutable
class EquipmentType {
  const EquipmentType({required this.id, required this.name});

  final String id;
  final String name;

  factory EquipmentType.fromJson(Map<String, dynamic> json) =>
      EquipmentType(id: J.str(json['id']), name: J.str(json['name']));

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EquipmentType && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Valores de `status` que usa el backend para la maquinaria.
abstract final class EquipmentStatus {
  static const String available = 'Available';
  static const String assigned = 'Assigned';
  static const String inMaintenance = 'In Maintenance';
}

/// Régimen de tenencia de la máquina.
abstract final class OwnershipType {
  static const String owned = 'Owned';
  static const String rented = 'Rented';
}

/// Máquina o equipo (`/equipment`).
@immutable
class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    this.typeId,
    this.plateNumber = '',
    this.model = '',
    this.brand = '',
    this.status = EquipmentStatus.available,
    this.ownershipType = OwnershipType.owned,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? typeId;
  final String plateNumber;
  final String model;
  final String brand;
  final String status;
  final String ownershipType;
  final DateTime? createdAt;

  bool get isAvailable => status == EquipmentStatus.available;

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
    id: J.str(json['id']),
    name: J.str(json['name']),
    typeId: J.strOrNull(json['type_id']),
    plateNumber: J.str(json['plate_number']),
    model: J.str(json['model']),
    brand: J.str(json['brand']),
    status: J.str(json['status']),
    ownershipType: J.str(json['ownership_type']),
    createdAt: Fmt.parseDate(json['created_at']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'type_id': ?typeId,
    'name': name,
    'plate_number': plateNumber,
    'model': model,
    'brand': brand,
    'status': status,
    'ownership_type': ownershipType,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Equipment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Asignación de una máquina a un proyecto (`/equipment/assignments`).
@immutable
class EquipmentAssignment {
  const EquipmentAssignment({
    required this.id,
    required this.equipmentId,
    required this.projectId,
    this.startDate,
    this.endDate,
    this.notes = '',
  });

  final String id;
  final String equipmentId;
  final String projectId;

  /// Campos solo-fecha (`YYYY-MM-DD`).
  final DateTime? startDate;
  final DateTime? endDate;
  final String notes;

  factory EquipmentAssignment.fromJson(Map<String, dynamic> json) =>
      EquipmentAssignment(
        id: J.str(json['id']),
        equipmentId: J.str(json['equipment_id']),
        projectId: J.str(json['project_id']),
        startDate: Fmt.parseDate(json['start_date']),
        endDate: Fmt.parseDate(json['end_date']),
        notes: J.str(json['notes']),
      );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'equipment_id': equipmentId,
    'project_id': projectId,
    if (startDate != null) 'start_date': Fmt.apiDate(startDate!),
    if (endDate != null) 'end_date': Fmt.apiDate(endDate!),
    'notes': notes,
  };
}

/// Tipo de mantenimiento admitido por la API.
abstract final class MaintenanceType {
  static const String preventive = 'Preventive';
  static const String corrective = 'Corrective';
}

/// Registro de mantenimiento (`/equipment/maintenances`).
@immutable
class MaintenanceRecord {
  const MaintenanceRecord({
    required this.id,
    required this.equipmentId,
    this.maintenanceType = MaintenanceType.preventive,
    this.description = '',
    this.cost = 0,
    this.maintenanceDate,
    this.nextDueDate,
  });

  final String id;
  final String equipmentId;
  final String maintenanceType;
  final String description;
  final double cost;
  final DateTime? maintenanceDate;
  final DateTime? nextDueDate;

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      MaintenanceRecord(
        id: J.str(json['id']),
        equipmentId: J.str(json['equipment_id']),
        maintenanceType: J.str(json['maintenance_type']),
        description: J.str(json['description']),
        cost: J.dbl(json['cost']),
        maintenanceDate: Fmt.parseDate(json['maintenance_date']),
        nextDueDate: Fmt.parseDate(json['next_due_date']),
      );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'equipment_id': equipmentId,
    'maintenance_type': maintenanceType,
    'description': description,
    'cost': cost,
    if (maintenanceDate != null)
      'maintenance_date': Fmt.apiDate(maintenanceDate!),
    if (nextDueDate != null) 'next_due_date': Fmt.apiDate(nextDueDate!),
  };
}
