import 'package:flutter/foundation.dart';

import 'common_strings.dart';

/// Textos de los módulos de recursos: inventario, maquinaria, personal y
/// documentos.
@immutable
class InventoryStrings {
  const InventoryStrings({
    required this.tabWarehouses,
    required this.tabMaterials,
    required this.stockTitle,
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
    required this.viewStock,
    required this.stockOf,
    required this.newWarehouse,
    required this.warehouseName,
    required this.warehouseNameRequired,
    required this.warehouseSubmit,
    required this.warehouseCreated,
    required this.projectsError,
    required this.projectRequired,
    required this.newMaterial,
    required this.materialName,
    required this.materialNameRequired,
    required this.materialCode,
    required this.materialCodeRequired,
    required this.materialUnit,
    required this.materialUnitRequired,
    required this.materialSubmit,
    required this.materialCreated,
    required this.movementTitle,
    required this.movementSubmit,
    required this.movementCreated,
    required this.movementTypeLabel,
    required this.movements,
    required this.materialLabel,
    required this.materialRequired,
    required this.referenceOptional,
    required this.noMaterialsForMovement,
  });

  final String tabWarehouses;
  final String tabMaterials;

  /// Rótulo de las existencias, usado como título de la hoja del ojo.
  final String stockTitle;

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

  // ── Existencias de un almacén ─────────────────────────────────────────
  final String viewStock;

  /// Título de la hoja de existencias: `{w}` es el almacén.
  final String stockOf;

  // ── Alta de almacén ───────────────────────────────────────────────────
  final String newWarehouse;
  final String warehouseName;
  final String warehouseNameRequired;
  final String warehouseSubmit;
  final String warehouseCreated;
  final String projectsError;
  final String projectRequired;

  // ── Alta de material ──────────────────────────────────────────────────
  final String newMaterial;
  final String materialName;
  final String materialNameRequired;
  final String materialCode;
  final String materialCodeRequired;
  final String materialUnit;
  final String materialUnitRequired;
  final String materialSubmit;
  final String materialCreated;

  // ── Movimiento de existencias ─────────────────────────────────────────
  final String movementTitle;
  final String movementSubmit;
  final String movementCreated;
  final String movementTypeLabel;

  /// Sentidos del movimiento, indexados por el valor exacto de la API
  /// (`INPUT`, `OUTPUT`), igual que los estados de asistencia.
  final Map<String, String> movements;

  final String materialLabel;
  final String materialRequired;
  final String referenceOptional;
  final String noMaterialsForMovement;

  String emptyWarehouseFor(String warehouse) =>
      fill(emptyWarehouseMessage, <String, String>{'w': warehouse});
  String stockTitleFor(String warehouse) =>
      fill(stockOf, <String, String>{'w': warehouse});
  String movement(String apiValue, String fallback) =>
      movements[apiValue] ?? fallback;
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
    required this.newPosition,
    required this.positionName,
    required this.positionNameRequired,
    required this.baseSalaryLabel,
    required this.positionSubmit,
    required this.positionCreated,
    required this.newEmployee,
    required this.employeeFirstName,
    required this.employeeFirstNameRequired,
    required this.employeeLastName,
    required this.employeeLastNameRequired,
    required this.employeePosition,
    required this.employeeDni,
    required this.employeeSubmit,
    required this.employeeCreated,
    required this.newContract,
    required this.contractEmployee,
    required this.contractEmployeeRequired,
    required this.contractEmployeeNotFound,
    required this.contractTypeLabel,
    required this.contractTypes,
    required this.contractSalary,
    required this.contractStart,
    required this.contractEnd,
    required this.contractSubmit,
    required this.contractCreated,
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

  // ── Formulario de cargo ───────────────────────────────────────────────
  final String newPosition;
  final String positionName;
  final String positionNameRequired;
  final String baseSalaryLabel;
  final String positionSubmit;
  final String positionCreated;

  // ── Formulario de empleado ─────────────────────────────────────────────
  final String newEmployee;
  final String employeeFirstName;
  final String employeeFirstNameRequired;
  final String employeeLastName;
  final String employeeLastNameRequired;
  final String employeePosition;
  final String employeeDni;
  final String employeeSubmit;
  final String employeeCreated;

  // ── Formulario de contrato ─────────────────────────────────────────────
  final String newContract;
  final String contractEmployee;
  final String contractEmployeeRequired;
  final String contractEmployeeNotFound;
  final String contractTypeLabel;

  /// Tipos de contrato, indexados por el valor exacto de la API.
  final Map<String, String> contractTypes;

  final String contractSalary;
  final String contractStart;
  final String contractEnd;
  final String contractSubmit;
  final String contractCreated;

  String nationalIdOf(String value) =>
      fill(nationalId, <String, String>{'v': value});
  String contractsEmptyFor(String project) =>
      fill(contractsEmptyMessage, <String, String>{'p': project});
  String contractType(String apiValue, String fallback) =>
      contractTypes[apiValue] ?? fallback;
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
  tabWarehouses: 'Almacenes',
  tabMaterials: 'Materiales',
  stockTitle: 'Existencias',
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
  viewStock: 'Ver materiales',
  stockOf: 'Existencias · {w}',
  newWarehouse: 'Nuevo almacén',
  warehouseName: 'Nombre del almacén',
  warehouseNameRequired: 'Ponle nombre al almacén',
  warehouseSubmit: 'Crear almacén',
  warehouseCreated: 'Almacén creado',
  projectsError: 'No se pudieron cargar las obras.',
  projectRequired: 'Elige la obra del almacén',
  newMaterial: 'Nuevo material',
  materialName: 'Nombre del material',
  materialNameRequired: 'Ponle nombre al material',
  materialCode: 'Código',
  materialCodeRequired: 'Ingresa el código',
  materialUnit: 'Unidad de medida',
  materialUnitRequired: 'Indica la unidad (saco, m³, tonelada…)',
  materialSubmit: 'Crear material',
  materialCreated: 'Material creado',
  movementTitle: 'Movimiento de existencias',
  movementSubmit: 'Registrar movimiento',
  movementCreated: 'Movimiento registrado',
  movementTypeLabel: 'Tipo de movimiento',
  movements: <String, String>{'INPUT': 'Entrada', 'OUTPUT': 'Salida'},
  materialLabel: 'Material',
  materialRequired: 'Elige un material',
  referenceOptional: 'Documento de referencia (opcional)',
  noMaterialsForMovement:
      'Primero da de alta un material en el catálogo para poder moverlo.',
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
  newPosition: 'Nuevo cargo',
  positionName: 'Nombre del cargo',
  positionNameRequired: 'Ponle nombre al cargo',
  baseSalaryLabel: 'Salario base',
  positionSubmit: 'Crear cargo',
  positionCreated: 'Cargo creado',
  newEmployee: 'Nuevo empleado',
  employeeFirstName: 'Nombre',
  employeeFirstNameRequired: 'Ponle nombre',
  employeeLastName: 'Apellido',
  employeeLastNameRequired: 'Ponle apellido',
  employeePosition: 'Cargo',
  employeeDni: 'DNI',
  employeeSubmit: 'Crear empleado',
  employeeCreated: 'Empleado creado',
  newContract: 'Nuevo contrato',
  contractEmployee: 'Empleado',
  contractEmployeeRequired: 'Elige un empleado',
  contractEmployeeNotFound:
      'Da de alta al empleado antes de asignarle un contrato.',
  contractTypeLabel: 'Tipo de contrato',
  contractTypes: <String, String>{
    'Indefinite': 'Indefinido',
    'Fixed': 'A plazo fijo',
    'Per Project': 'Por obra',
  },
  contractSalary: 'Salario',
  contractStart: 'Inicio del contrato',
  contractEnd: 'Fin del contrato',
  contractSubmit: 'Crear contrato',
  contractCreated: 'Contrato creado',
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
  tabWarehouses: 'Depósitos',
  tabMaterials: 'Materiais',
  stockTitle: 'Estoque',
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
  viewStock: 'Ver materiais',
  stockOf: 'Estoque · {w}',
  newWarehouse: 'Novo depósito',
  warehouseName: 'Nome do depósito',
  warehouseNameRequired: 'Dê um nome ao depósito',
  warehouseSubmit: 'Criar depósito',
  warehouseCreated: 'Depósito criado',
  projectsError: 'Não foi possível carregar as obras.',
  projectRequired: 'Escolha a obra do depósito',
  newMaterial: 'Novo material',
  materialName: 'Nome do material',
  materialNameRequired: 'Dê um nome ao material',
  materialCode: 'Código',
  materialCodeRequired: 'Digite o código',
  materialUnit: 'Unidade de medida',
  materialUnitRequired: 'Indique a unidade (saco, m³, tonelada…)',
  materialSubmit: 'Criar material',
  materialCreated: 'Material criado',
  movementTitle: 'Movimentação de estoque',
  movementSubmit: 'Registrar movimentação',
  movementCreated: 'Movimentação registrada',
  movementTypeLabel: 'Tipo de movimentação',
  movements: <String, String>{'INPUT': 'Entrada', 'OUTPUT': 'Saída'},
  materialLabel: 'Material',
  materialRequired: 'Escolha um material',
  referenceOptional: 'Documento de referência (opcional)',
  noMaterialsForMovement:
      'Cadastre primeiro um material no catálogo para poder movimentá-lo.',
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
  newPosition: 'Novo cargo',
  positionName: 'Nome do cargo',
  positionNameRequired: 'Dê um nome ao cargo',
  baseSalaryLabel: 'Salário-base',
  positionSubmit: 'Criar cargo',
  positionCreated: 'Cargo criado',
  newEmployee: 'Novo funcionário',
  employeeFirstName: 'Nome',
  employeeFirstNameRequired: 'Digite o nome',
  employeeLastName: 'Sobrenome',
  employeeLastNameRequired: 'Digite o sobrenome',
  employeePosition: 'Cargo',
  employeeDni: 'CPF',
  employeeSubmit: 'Criar funcionário',
  employeeCreated: 'Funcionário criado',
  newContract: 'Novo contrato',
  contractEmployee: 'Funcionário',
  contractEmployeeRequired: 'Escolha um funcionário',
  contractEmployeeNotFound:
      'Cadastre o funcionário antes de atribuir um contrato.',
  contractTypeLabel: 'Tipo de contrato',
  contractTypes: <String, String>{
    'Indefinite': 'Indeterminado',
    'Fixed': 'Prazo fixo',
    'Per Project': 'Por obra',
  },
  contractSalary: 'Salário',
  contractStart: 'Início do contrato',
  contractEnd: 'Fim do contrato',
  contractSubmit: 'Criar contrato',
  contractCreated: 'Contrato criado',
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
  tabWarehouses: 'Warehouses',
  tabMaterials: 'Materials',
  stockTitle: 'Stock',
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
  viewStock: 'View materials',
  stockOf: 'Stock · {w}',
  newWarehouse: 'New warehouse',
  warehouseName: 'Warehouse name',
  warehouseNameRequired: 'Name the warehouse',
  warehouseSubmit: 'Create warehouse',
  warehouseCreated: 'Warehouse created',
  projectsError: 'Sites could not be loaded.',
  projectRequired: 'Pick the warehouse’s site',
  newMaterial: 'New material',
  materialName: 'Material name',
  materialNameRequired: 'Name the material',
  materialCode: 'Code',
  materialCodeRequired: 'Enter the code',
  materialUnit: 'Unit of measure',
  materialUnitRequired: 'State the unit (bag, m³, tonne…)',
  materialSubmit: 'Create material',
  materialCreated: 'Material created',
  movementTitle: 'Stock movement',
  movementSubmit: 'Record movement',
  movementCreated: 'Movement recorded',
  movementTypeLabel: 'Movement type',
  movements: <String, String>{'INPUT': 'In', 'OUTPUT': 'Out'},
  materialLabel: 'Material',
  materialRequired: 'Pick a material',
  referenceOptional: 'Reference document (optional)',
  noMaterialsForMovement:
      'Add a material to the catalogue first so there is something to move.',
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
  newPosition: 'New position',
  positionName: 'Position name',
  positionNameRequired: 'Name the position',
  baseSalaryLabel: 'Base salary',
  positionSubmit: 'Create position',
  positionCreated: 'Position created',
  newEmployee: 'New employee',
  employeeFirstName: 'First name',
  employeeFirstNameRequired: 'Enter a first name',
  employeeLastName: 'Last name',
  employeeLastNameRequired: 'Enter a last name',
  employeePosition: 'Position',
  employeeDni: 'ID number',
  employeeSubmit: 'Create employee',
  employeeCreated: 'Employee created',
  newContract: 'New contract',
  contractEmployee: 'Employee',
  contractEmployeeRequired: 'Pick an employee',
  contractEmployeeNotFound: 'Add the employee before assigning a contract.',
  contractTypeLabel: 'Contract type',
  contractTypes: <String, String>{
    'Indefinite': 'Indefinite',
    'Fixed': 'Fixed-term',
    'Per Project': 'Per site',
  },
  contractSalary: 'Salary',
  contractStart: 'Contract start',
  contractEnd: 'Contract end',
  contractSubmit: 'Create contract',
  contractCreated: 'Contract created',
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
