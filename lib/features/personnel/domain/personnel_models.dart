import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Cargo con su salario base (`/positions`).
@immutable
class Position {
  const Position({required this.id, required this.name, this.baseSalary = 0});

  final String id;
  final String name;
  final double baseSalary;

  factory Position.fromJson(Map<String, dynamic> json) => Position(
    id: J.str(json['id']),
    name: J.str(json['name']),
    baseSalary: J.dbl(json['base_salary']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'name': name,
    'base_salary': baseSalary,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Position && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Estados de un empleado según el backend.
abstract final class EmployeeStatus {
  static const String active = 'Active';
  static const String inactive = 'Inactive';
}

/// Trabajador de la empresa (`/employees`).
@immutable
class Employee {
  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.positionId,
    this.dni = '',
    this.phone = '',
    this.email = '',
    this.status = EmployeeStatus.active,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? positionId;
  final String dni;
  final String phone;
  final String email;
  final String status;

  String get fullName => '$firstName $lastName'.trim();

  bool get isActive => status == EmployeeStatus.active;

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: J.str(json['id']),
    firstName: J.str(json['first_name']),
    lastName: J.str(json['last_name']),
    positionId: J.strOrNull(json['position_id']),
    dni: J.str(json['dni']),
    phone: J.str(json['phone']),
    email: J.str(json['email']),
    status: J.str(json['status']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'position_id': ?positionId,
    'first_name': firstName,
    'last_name': lastName,
    'dni': dni,
    'phone': phone,
    'email': email,
    'status': status,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Employee && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Tipos de contrato laboral que admite la API.
abstract final class ContractType {
  static const String indefinite = 'Indefinite';
  static const String fixed = 'Fixed';
  static const String perProject = 'Per Project';

  /// Nombre interno por si la traducción no conoce el tipo.
  static String labelFor(String apiValue) => switch (apiValue) {
    perProject => 'Per Project',
    fixed => 'Fixed',
    _ => 'Indefinite',
  };

  /// Todos los valores, en el orden en que se muestran.
  static List<String> get values => <String>[indefinite, fixed, perProject];
}

/// Contrato laboral de un empleado en un proyecto (`/contracts`).
@immutable
class LaborContract {
  const LaborContract({
    required this.id,
    required this.employeeId,
    required this.projectId,
    this.contractType = ContractType.indefinite,
    this.salary = 0,
    this.startDate,
    this.endDate,
    this.status = EmployeeStatus.active,
  });

  final String id;
  final String employeeId;
  final String projectId;
  final String contractType;
  final double salary;

  /// Campos solo-fecha (`YYYY-MM-DD`).
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  factory LaborContract.fromJson(Map<String, dynamic> json) => LaborContract(
    id: J.str(json['id']),
    employeeId: J.str(json['employee_id']),
    projectId: J.str(json['project_id']),
    contractType: J.str(json['contract_type']),
    salary: J.dbl(json['salary']),
    startDate: Fmt.parseDate(json['start_date']),
    endDate: Fmt.parseDate(json['end_date']),
    status: J.str(json['status']),
  );

  /// Cuerpo de `POST /contracts` (incluye los identificadores).
  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'employee_id': employeeId,
    'project_id': projectId,
    ...toUpdateBody(),
  };

  /// Cuerpo de `PUT /contracts/{id}`: el backend no permite mover el contrato
  /// de empleado ni de proyecto.
  Map<String, dynamic> toUpdateBody() => <String, dynamic>{
    'contract_type': contractType,
    'salary': salary,
    if (startDate != null) 'start_date': Fmt.apiDate(startDate!),
    if (endDate != null) 'end_date': Fmt.apiDate(endDate!),
    'status': status,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LaborContract && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
