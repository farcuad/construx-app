import 'package:flutter/foundation.dart';

import 'common_strings.dart';

/// Textos de los módulos de recursos: inventario, maquinaria, personal y
/// documentos.
@immutable
class InventoryStrings {
  const InventoryStrings({
    required this.tabStock,
    required this.tabMaterials,
    required this.warehousesError,
    required this.noWarehousesTitle,
    required this.noWarehousesMessage,
    required this.stockError,
    required this.emptyWarehouseTitle,
    required this.emptyWarehouseMessage,
    required this.unnamedMaterial,
    required this.materialsError,
    required this.noMaterialsTitle,
    required this.noMaterialsMessage,
  });

  final String tabStock;
  final String tabMaterials;
  final String warehousesError;
  final String noWarehousesTitle;
  final String noWarehousesMessage;
  final String stockError;
  final String emptyWarehouseTitle;
  final String emptyWarehouseMessage;
  final String unnamedMaterial;
  final String materialsError;
  final String noMaterialsTitle;
  final String noMaterialsMessage;

  String emptyWarehouseFor(String warehouse) =>
      fill(emptyWarehouseMessage, <String, String>{'w': warehouse});
}

@immutable
class EquipmentStrings {
  const EquipmentStrings({
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.assignments,
    required this.assignmentsError,
    required this.noAssignments,
    required this.maintenances,
    required this.maintenancesError,
    required this.noMaintenances,
    required this.untitledMaintenance,
  });

  final String loadError;
  final String emptyTitle;
  final String emptyMessage;
  final String assignments;
  final String assignmentsError;
  final String noAssignments;
  final String maintenances;
  final String maintenancesError;
  final String noMaintenances;
  final String untitledMaintenance;
}

@immutable
class PersonnelStrings {
  const PersonnelStrings({
    required this.tabEmployees,
    required this.tabPositions,
    required this.tabContracts,
    required this.employeesError,
    required this.employeesEmptyTitle,
    required this.employeesEmptyMessage,
    required this.nationalId,
    required this.positionsError,
    required this.positionsEmptyTitle,
    required this.positionsEmptyMessage,
    required this.baseSalaryUpper,
    required this.needsProject,
    required this.contractsError,
    required this.contractsEmptyTitle,
    required this.contractsEmptyMessage,
    required this.unnamedEmployee,
    required this.salaryUpper,
    required this.fromUpper,
    required this.toUpper,
  });

  final String tabEmployees;
  final String tabPositions;
  final String tabContracts;
  final String employeesError;
  final String employeesEmptyTitle;
  final String employeesEmptyMessage;

  /// Documento de identidad. Con `{v}` como hueco para el número.
  final String nationalId;

  final String positionsError;
  final String positionsEmptyTitle;
  final String positionsEmptyMessage;
  final String baseSalaryUpper;
  final String needsProject;
  final String contractsError;
  final String contractsEmptyTitle;
  final String contractsEmptyMessage;
  final String unnamedEmployee;
  final String salaryUpper;
  final String fromUpper;
  final String toUpper;

  String nationalIdOf(String value) =>
      fill(nationalId, <String, String>{'v': value});
  String contractsEmptyFor(String project) =>
      fill(contractsEmptyMessage, <String, String>{'p': project});
}

@immutable
class DocumentsStrings {
  const DocumentsStrings({
    required this.needsProject,
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.untitled,
    required this.noType,
    required this.noVersions,
    required this.noNotes,
  });

  final String needsProject;
  final String loadError;
  final String emptyTitle;
  final String emptyMessage;
  final String untitled;
  final String noType;
  final String noVersions;
  final String noNotes;

  String emptyFor(String project) =>
      fill(emptyMessage, <String, String>{'p': project});
}

// ─────────────────────────────── español ────────────────────────────────

const InventoryStrings kInventoryEs = InventoryStrings(
  tabStock: 'Existencias',
  tabMaterials: 'Materiales',
  warehousesError: 'No se pudieron cargar los almacenes.',
  noWarehousesTitle: 'Sin almacenes',
  noWarehousesMessage: 'Crea un almacén para poder controlar existencias.',
  stockError: 'No se pudieron cargar las existencias.',
  emptyWarehouseTitle: 'Almacén vacío',
  emptyWarehouseMessage: '«{w}» no tiene existencias registradas.',
  unnamedMaterial: 'Material',
  materialsError: 'No se pudieron cargar los materiales.',
  noMaterialsTitle: 'Sin materiales',
  noMaterialsMessage: 'El catálogo de materiales está vacío.',
);

const EquipmentStrings kEquipmentEs = EquipmentStrings(
  loadError: 'No se pudo cargar la maquinaria.',
  emptyTitle: 'Sin maquinaria',
  emptyMessage: 'Aquí aparecerán las máquinas propias y las alquiladas.',
  assignments: 'Asignaciones',
  assignmentsError: 'No se pudieron cargar las asignaciones.',
  noAssignments: 'Sin asignaciones a obra.',
  maintenances: 'Mantenimientos',
  maintenancesError: 'No se pudo cargar el mantenimiento.',
  noMaintenances: 'Sin mantenimientos registrados.',
  untitledMaintenance: 'Mantenimiento',
);

const PersonnelStrings kPersonnelEs = PersonnelStrings(
  tabEmployees: 'Empleados',
  tabPositions: 'Cargos',
  tabContracts: 'Contratos',
  employeesError: 'No se pudo cargar la plantilla.',
  employeesEmptyTitle: 'Sin empleados',
  employeesEmptyMessage: 'Aquí aparecerá la plantilla de la empresa.',
  nationalId: 'DNI {v}',
  positionsError: 'No se pudieron cargar los cargos.',
  positionsEmptyTitle: 'Sin cargos',
  positionsEmptyMessage: 'Los cargos definen el salario base de cada puesto.',
  baseSalaryUpper: 'SALARIO BASE',
  needsProject: 'Los contratos laborales se asignan a una obra.',
  contractsError: 'No se pudieron cargar los contratos.',
  contractsEmptyTitle: 'Sin contratos',
  contractsEmptyMessage: 'Nadie tiene contrato asignado a «{p}».',
  unnamedEmployee: 'Empleado',
  salaryUpper: 'SALARIO',
  fromUpper: 'DESDE',
  toUpper: 'HASTA',
);

const DocumentsStrings kDocumentsEs = DocumentsStrings(
  needsProject: 'Los documentos se archivan por obra.',
  loadError: 'No se pudieron cargar los documentos.',
  emptyTitle: 'Sin documentos',
  emptyMessage: '«{p}» no tiene documentos archivados.',
  untitled: 'Documento',
  noType: 'Sin tipo',
  noVersions: 'Sin versiones registradas',
  noNotes: 'Sin notas',
);

// ────────────────────────────── português ───────────────────────────────

const InventoryStrings kInventoryPt = InventoryStrings(
  tabStock: 'Estoque',
  tabMaterials: 'Materiais',
  warehousesError: 'Não foi possível carregar os depósitos.',
  noWarehousesTitle: 'Sem depósitos',
  noWarehousesMessage: 'Crie um depósito para poder controlar o estoque.',
  stockError: 'Não foi possível carregar o estoque.',
  emptyWarehouseTitle: 'Depósito vazio',
  emptyWarehouseMessage: '«{w}» não tem estoque registrado.',
  unnamedMaterial: 'Material',
  materialsError: 'Não foi possível carregar os materiais.',
  noMaterialsTitle: 'Sem materiais',
  noMaterialsMessage: 'O catálogo de materiais está vazio.',
);

const EquipmentStrings kEquipmentPt = EquipmentStrings(
  loadError: 'Não foi possível carregar o maquinário.',
  emptyTitle: 'Sem maquinário',
  emptyMessage: 'Aqui aparecerão as máquinas próprias e as alugadas.',
  assignments: 'Alocações',
  assignmentsError: 'Não foi possível carregar as alocações.',
  noAssignments: 'Sem alocações em obra.',
  maintenances: 'Manutenções',
  maintenancesError: 'Não foi possível carregar a manutenção.',
  noMaintenances: 'Sem manutenções registradas.',
  untitledMaintenance: 'Manutenção',
);

const PersonnelStrings kPersonnelPt = PersonnelStrings(
  tabEmployees: 'Funcionários',
  tabPositions: 'Cargos',
  tabContracts: 'Contratos',
  employeesError: 'Não foi possível carregar o quadro de pessoal.',
  employeesEmptyTitle: 'Sem funcionários',
  employeesEmptyMessage: 'Aqui aparecerá o quadro de pessoal da empresa.',
  nationalId: 'CPF {v}',
  positionsError: 'Não foi possível carregar os cargos.',
  positionsEmptyTitle: 'Sem cargos',
  positionsEmptyMessage: 'Os cargos definem o salário-base de cada posto.',
  baseSalaryUpper: 'SALÁRIO-BASE',
  needsProject: 'Os contratos de trabalho são atribuídos a uma obra.',
  contractsError: 'Não foi possível carregar os contratos.',
  contractsEmptyTitle: 'Sem contratos',
  contractsEmptyMessage: 'Ninguém tem contrato atribuído a «{p}».',
  unnamedEmployee: 'Funcionário',
  salaryUpper: 'SALÁRIO',
  fromUpper: 'DESDE',
  toUpper: 'ATÉ',
);

const DocumentsStrings kDocumentsPt = DocumentsStrings(
  needsProject: 'Os documentos são arquivados por obra.',
  loadError: 'Não foi possível carregar os documentos.',
  emptyTitle: 'Sem documentos',
  emptyMessage: '«{p}» não tem documentos arquivados.',
  untitled: 'Documento',
  noType: 'Sem tipo',
  noVersions: 'Sem versões registradas',
  noNotes: 'Sem observações',
);

// ─────────────────────────────── english ────────────────────────────────

const InventoryStrings kInventoryEn = InventoryStrings(
  tabStock: 'Stock',
  tabMaterials: 'Materials',
  warehousesError: 'Warehouses could not be loaded.',
  noWarehousesTitle: 'No warehouses',
  noWarehousesMessage: 'Create a warehouse to start tracking stock.',
  stockError: 'Stock could not be loaded.',
  emptyWarehouseTitle: 'Empty warehouse',
  emptyWarehouseMessage: '“{w}” has no stock recorded.',
  unnamedMaterial: 'Material',
  materialsError: 'Materials could not be loaded.',
  noMaterialsTitle: 'No materials',
  noMaterialsMessage: 'The material catalogue is empty.',
);

const EquipmentStrings kEquipmentEn = EquipmentStrings(
  loadError: 'Machinery could not be loaded.',
  emptyTitle: 'No machinery',
  emptyMessage: 'Owned and rented machines will show up here.',
  assignments: 'Assignments',
  assignmentsError: 'Assignments could not be loaded.',
  noAssignments: 'Not assigned to any site.',
  maintenances: 'Maintenance',
  maintenancesError: 'Maintenance could not be loaded.',
  noMaintenances: 'No maintenance recorded.',
  untitledMaintenance: 'Maintenance',
);

const PersonnelStrings kPersonnelEn = PersonnelStrings(
  tabEmployees: 'Employees',
  tabPositions: 'Positions',
  tabContracts: 'Contracts',
  employeesError: 'The staff list could not be loaded.',
  employeesEmptyTitle: 'No employees',
  employeesEmptyMessage: 'Your company’s staff will show up here.',
  nationalId: 'ID {v}',
  positionsError: 'Positions could not be loaded.',
  positionsEmptyTitle: 'No positions',
  positionsEmptyMessage: 'Positions set the base salary for each role.',
  baseSalaryUpper: 'BASE SALARY',
  needsProject: 'Employment contracts are assigned to a site.',
  contractsError: 'Contracts could not be loaded.',
  contractsEmptyTitle: 'No contracts',
  contractsEmptyMessage: 'Nobody is contracted to “{p}”.',
  unnamedEmployee: 'Employee',
  salaryUpper: 'SALARY',
  fromUpper: 'FROM',
  toUpper: 'TO',
);

const DocumentsStrings kDocumentsEn = DocumentsStrings(
  needsProject: 'Documents are filed per site.',
  loadError: 'Documents could not be loaded.',
  emptyTitle: 'No documents',
  emptyMessage: '“{p}” has no documents on file.',
  untitled: 'Document',
  noType: 'No type',
  noVersions: 'No versions recorded',
  noNotes: 'No notes',
);
