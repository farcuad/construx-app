import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/features/attendance/data/attendance_repository.dart';
import 'package:mi_app_constructora/features/attendance/domain/attendance_models.dart';
import 'package:mi_app_constructora/features/audits/data/audits_repository.dart';
import 'package:mi_app_constructora/features/budgets/data/budgets_repository.dart';
import 'package:mi_app_constructora/features/budgets/domain/budget.dart';
import 'package:mi_app_constructora/features/clients/data/clients_repository.dart';
import 'package:mi_app_constructora/features/clients/domain/client.dart';
import 'package:mi_app_constructora/features/contractors/data/contractors_repository.dart';
import 'package:mi_app_constructora/features/contractors/domain/contractor_models.dart';
import 'package:mi_app_constructora/features/documents/data/documents_repository.dart';
import 'package:mi_app_constructora/features/documents/domain/document_models.dart';
import 'package:mi_app_constructora/features/equipment/data/equipment_repository.dart';
import 'package:mi_app_constructora/features/equipment/domain/equipment_models.dart';
import 'package:mi_app_constructora/features/expenses/data/expenses_repository.dart';
import 'package:mi_app_constructora/features/expenses/domain/expense.dart';
import 'package:mi_app_constructora/features/inventory/data/inventory_repository.dart';
import 'package:mi_app_constructora/features/inventory/domain/inventory_models.dart';
import 'package:mi_app_constructora/features/invoices/data/invoices_repository.dart';
import 'package:mi_app_constructora/features/invoices/domain/invoice_models.dart';
import 'package:mi_app_constructora/features/notifications/data/notifications_repository.dart';
import 'package:mi_app_constructora/features/notifications/domain/notification_models.dart';
import 'package:mi_app_constructora/features/personnel/data/personnel_repository.dart';
import 'package:mi_app_constructora/features/personnel/domain/personnel_models.dart';
import 'package:mi_app_constructora/features/photos/data/photos_repository.dart';
import 'package:mi_app_constructora/features/photos/domain/project_photo.dart';
import 'package:mi_app_constructora/features/progress/data/progress_repository.dart';
import 'package:mi_app_constructora/features/progress/domain/daily_report.dart';
import 'package:mi_app_constructora/features/projects/data/projects_repository.dart';
import 'package:mi_app_constructora/features/projects/domain/project.dart';
import 'package:mi_app_constructora/features/purchases/data/purchases_repository.dart';
import 'package:mi_app_constructora/features/purchases/domain/purchase_order.dart';
import 'package:mi_app_constructora/features/schedule/data/schedule_repository.dart';
import 'package:mi_app_constructora/features/schedule/domain/schedule_task.dart';
import 'package:mi_app_constructora/features/subscriptions/data/subscriptions_repository.dart';
import 'package:mi_app_constructora/features/suppliers/data/suppliers_repository.dart';
import 'package:mi_app_constructora/features/suppliers/domain/supplier.dart';
import 'package:mi_app_constructora/features/users/data/users_repository.dart';

import '../helpers/test_helpers.dart';

/// Un endpoint de la documentación y la llamada del repositorio que debería
/// producirlo.
typedef EndpointCase = ({
  String method,
  String path,
  Object? response,
  Future<Object?> Function(ApiClient api) call,
});

/// Rutas públicas de la API: no deben mandar `Authorization`.
///
/// La app es para trabajadores, así que `/login` es la única. El alta de
/// empresas y el acceso del superadministrador se hacen desde la web.
const Set<String> kPublicPaths = <String>{'/login'};

void main() {
  /// Respuestas genéricas según la forma que espera cada repositorio.
  const List<Map<String, dynamic>> emptyList = <Map<String, dynamic>>[];
  const Map<String, dynamic> emptyObject = <String, dynamic>{};

  final DateTime day = DateTime(2026, 8, 8);

  // Instancias mínimas para las llamadas de escritura. Lo que se comprueba es
  // el verbo y la URL, no el cuerpo (eso lo cubren las pruebas de modelos).
  const Project project = Project(id: 'p1', name: 'Obra');
  const Client client = Client(id: 'c1', name: 'Cliente');
  const Budget budget = Budget(id: 'b1', projectId: 'p1', title: 'Presupuesto');
  const Expense expense = Expense(
    id: 'e1',
    projectId: 'p1',
    title: 'Gasto',
    amount: 100,
  );
  const Supplier supplier = Supplier(id: 's1', name: 'Proveedor');
  const PurchaseOrder order = PurchaseOrder(id: 'o1', projectId: 'p1');
  const InventoryMaterial material = InventoryMaterial(
    id: 'm1',
    name: 'Cemento',
  );
  const Warehouse warehouse = Warehouse(id: 'w1', name: 'Bodega');
  const StockMovement movement = StockMovement(
    id: 'mv1',
    warehouseId: 'w1',
    materialId: 'm1',
    type: MovementType.input,
    quantity: 5,
  );
  const Equipment equipment = Equipment(id: 'eq1', name: 'Retro');
  const EquipmentAssignment assignment = EquipmentAssignment(
    id: 'a1',
    equipmentId: 'eq1',
    projectId: 'p1',
  );
  const MaintenanceRecord maintenance = MaintenanceRecord(
    id: 'mt1',
    equipmentId: 'eq1',
  );
  const Position position = Position(id: 'pos1', name: 'Oficial');
  const Employee employee = Employee(
    id: 'emp1',
    firstName: 'Carlos',
    lastName: 'Ruiz',
  );
  const LaborContract laborContract = LaborContract(
    id: 'lc1',
    employeeId: 'emp1',
    projectId: 'p1',
  );
  const Contractor contractor = Contractor(id: 'ct1', name: 'Contratista');
  const ContractorContract contractorContract = ContractorContract(
    id: 'cc1',
    contractorId: 'ct1',
    projectId: 'p1',
    title: 'Cimentación',
  );
  const ContractorPayment contractorPayment = ContractorPayment(
    id: 'cp1',
    contractId: 'cc1',
    amount: 100,
  );
  const ScheduleTask task = ScheduleTask(
    id: 't1',
    projectId: 'p1',
    name: 'Excavación',
  );
  final DailyReport report = DailyReport(
    id: 'r1',
    projectId: 'p1',
    reportDate: day,
  );
  const ProjectPhoto photo = ProjectPhoto(
    id: 'ph1',
    projectId: 'p1',
    photoUrl: 'https://x/f.jpg',
  );
  const Invoice invoice = Invoice(
    id: 'i1',
    projectId: 'p1',
    invoiceNumber: 'FAC-0001',
  );
  const Payment payment = Payment(id: 'pay1', invoiceId: 'i1', amount: 10);
  const DocumentVersion version = DocumentVersion(
    id: 'v1',
    documentId: 'd1',
    versionNumber: 2,
    fileUrl: 'https://x/f.pdf',
  );
  const AppNotification notification = AppNotification(
    id: 'n1',
    title: 'Aviso',
  );

  final List<EndpointCase> cases = <EndpointCase>[
    // ── Usuarios y roles ─────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/roles',
      response: emptyList,
      call: (ApiClient api) => UsersRepository(api).fetchRoles(),
    ),
    (
      method: 'GET',
      path: '/users',
      response: emptyList,
      call: (ApiClient api) => UsersRepository(api).fetchUsers(),
    ),
    (
      method: 'POST',
      path: '/users',
      response: emptyObject,
      call: (ApiClient api) => UsersRepository(
        api,
      ).create(name: 'María', email: 'm@xyz.com', password: 'x', roleId: 'r1'),
    ),
    (
      method: 'PUT',
      path: '/users/u1',
      response: emptyObject,
      call: (ApiClient api) => UsersRepository(api).update(
        'u1',
        name: 'María',
        email: 'm@xyz.com',
        roleId: 'r1',
        isActive: true,
      ),
    ),
    (
      method: 'DELETE',
      path: '/users/u1',
      response: null,
      call: (ApiClient api) => UsersRepository(api).delete('u1'),
    ),

    // ── Proyectos y dashboard ────────────────────────────────────────────
    (
      method: 'GET',
      path: '/projects',
      response: emptyList,
      call: (ApiClient api) => ProjectsRepository(api).fetchAll(),
    ),
    (
      method: 'POST',
      path: '/projects',
      response: emptyObject,
      call: (ApiClient api) => ProjectsRepository(api).create(project),
    ),
    (
      method: 'PUT',
      path: '/projects/p1',
      response: emptyObject,
      call: (ApiClient api) => ProjectsRepository(api).update(project),
    ),
    (
      method: 'DELETE',
      path: '/projects/p1',
      response: null,
      call: (ApiClient api) => ProjectsRepository(api).delete('p1'),
    ),
    (
      method: 'GET',
      path: '/dashboard/financial/p1',
      response: emptyObject,
      call: (ApiClient api) => ProjectsRepository(api).fetchKpis('p1'),
    ),

    // ── Clientes ─────────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/clients',
      response: emptyList,
      call: (ApiClient api) => ClientsRepository(api).fetchAll(),
    ),
    (
      method: 'POST',
      path: '/clients',
      response: emptyObject,
      call: (ApiClient api) => ClientsRepository(api).create(client),
    ),
    (
      method: 'PUT',
      path: '/clients/c1',
      response: emptyObject,
      call: (ApiClient api) => ClientsRepository(api).update(client),
    ),
    (
      method: 'DELETE',
      path: '/clients/c1',
      response: null,
      call: (ApiClient api) => ClientsRepository(api).delete('c1'),
    ),

    // ── Presupuestos ─────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/budgets/p1',
      response: emptyList,
      call: (ApiClient api) => BudgetsRepository(api).fetchByProject('p1'),
    ),
    (
      method: 'POST',
      path: '/budgets',
      response: emptyObject,
      call: (ApiClient api) => BudgetsRepository(api).create(budget),
    ),
    (
      method: 'PUT',
      path: '/budgets/b1',
      response: emptyObject,
      call: (ApiClient api) =>
          BudgetsRepository(api).update('b1', title: 'Otro'),
    ),
    (
      method: 'DELETE',
      path: '/budgets/b1',
      response: null,
      call: (ApiClient api) => BudgetsRepository(api).delete('b1'),
    ),

    // ── Gastos ───────────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/expenses/p1',
      response: emptyList,
      call: (ApiClient api) => ExpensesRepository(api).fetchByProject('p1'),
    ),
    (
      method: 'POST',
      path: '/expenses',
      response: emptyObject,
      call: (ApiClient api) => ExpensesRepository(api).create(expense),
    ),
    (
      method: 'PUT',
      path: '/expenses/e1',
      response: emptyObject,
      call: (ApiClient api) =>
          ExpensesRepository(api).update('e1', amount: 200),
    ),
    (
      method: 'DELETE',
      path: '/expenses/e1',
      response: null,
      call: (ApiClient api) => ExpensesRepository(api).delete('e1'),
    ),

    // ── Órdenes de compra (ruta con la errata /purcharse) ────────────────
    (
      method: 'GET',
      path: '/purcharse/p1',
      response: emptyList,
      call: (ApiClient api) => PurchasesRepository(api).fetchByProject('p1'),
    ),
    (
      method: 'POST',
      path: '/purcharse',
      response: emptyObject,
      call: (ApiClient api) => PurchasesRepository(api).create(order),
    ),
    (
      method: 'PUT',
      path: '/purcharse/o1',
      response: emptyObject,
      call: (ApiClient api) => PurchasesRepository(api).approve('o1'),
    ),
    (
      method: 'DELETE',
      path: '/purcharse/o1',
      response: null,
      call: (ApiClient api) => PurchasesRepository(api).delete('o1'),
    ),

    // ── Proveedores (ruta en singular /supplier) ─────────────────────────
    (
      method: 'GET',
      path: '/supplier',
      response: emptyList,
      call: (ApiClient api) => SuppliersRepository(api).fetchAll(),
    ),
    (
      method: 'POST',
      path: '/supplier',
      response: emptyObject,
      call: (ApiClient api) => SuppliersRepository(api).create(supplier),
    ),
    (
      method: 'PUT',
      path: '/supplier/s1',
      response: emptyObject,
      call: (ApiClient api) => SuppliersRepository(api).update(supplier),
    ),
    (
      method: 'DELETE',
      path: '/supplier/s1',
      response: null,
      call: (ApiClient api) => SuppliersRepository(api).delete('s1'),
    ),

    // ── Inventario ───────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/materials',
      response: emptyList,
      call: (ApiClient api) => InventoryRepository(api).fetchMaterials(),
    ),
    (
      method: 'POST',
      path: '/materials',
      response: emptyObject,
      call: (ApiClient api) =>
          InventoryRepository(api).createMaterial(material),
    ),
    (
      method: 'PUT',
      path: '/materials/m1',
      response: emptyObject,
      call: (ApiClient api) =>
          InventoryRepository(api).updateMaterial(material),
    ),
    (
      method: 'DELETE',
      path: '/materials/m1',
      response: null,
      call: (ApiClient api) => InventoryRepository(api).deleteMaterial('m1'),
    ),
    (
      method: 'GET',
      path: '/warehouses',
      response: emptyList,
      call: (ApiClient api) => InventoryRepository(api).fetchWarehouses(),
    ),
    (
      method: 'POST',
      path: '/warehouses',
      response: emptyObject,
      call: (ApiClient api) =>
          InventoryRepository(api).createWarehouse(warehouse),
    ),
    (
      method: 'PUT',
      path: '/warehouses/w1',
      response: emptyObject,
      call: (ApiClient api) =>
          InventoryRepository(api).updateWarehouse('w1', name: 'Bodega 2'),
    ),
    (
      method: 'DELETE',
      path: '/warehouses/w1',
      response: null,
      call: (ApiClient api) => InventoryRepository(api).deleteWarehouse('w1'),
    ),
    (
      method: 'POST',
      path: '/inventory/movements',
      response: emptyObject,
      call: (ApiClient api) =>
          InventoryRepository(api).registerMovement(movement),
    ),
    (
      method: 'GET',
      path: '/inventory/stock/w1',
      response: emptyList,
      call: (ApiClient api) => InventoryRepository(api).fetchStock('w1'),
    ),

    // ── Maquinaria ───────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/equipment/types',
      response: emptyList,
      call: (ApiClient api) => EquipmentRepository(api).fetchTypes(),
    ),
    (
      method: 'POST',
      path: '/equipment/types',
      response: emptyObject,
      call: (ApiClient api) =>
          EquipmentRepository(api).createType('Excavadora'),
    ),
    (
      method: 'GET',
      path: '/equipment',
      response: emptyList,
      call: (ApiClient api) => EquipmentRepository(api).fetchAll(),
    ),
    (
      method: 'POST',
      path: '/equipment',
      response: emptyObject,
      call: (ApiClient api) => EquipmentRepository(api).create(equipment),
    ),
    (
      method: 'PUT',
      path: '/equipment/eq1',
      response: emptyObject,
      call: (ApiClient api) => EquipmentRepository(api).update(equipment),
    ),
    (
      method: 'DELETE',
      path: '/equipment/eq1',
      response: null,
      call: (ApiClient api) => EquipmentRepository(api).delete('eq1'),
    ),
    (
      method: 'POST',
      path: '/equipment/assignments',
      response: emptyObject,
      call: (ApiClient api) => EquipmentRepository(api).assign(assignment),
    ),
    (
      method: 'GET',
      path: '/equipment/assignments/eq1',
      response: emptyList,
      call: (ApiClient api) => EquipmentRepository(api).fetchAssignments('eq1'),
    ),
    (
      method: 'POST',
      path: '/equipment/maintenances',
      response: emptyObject,
      call: (ApiClient api) =>
          EquipmentRepository(api).registerMaintenance(maintenance),
    ),
    (
      method: 'GET',
      path: '/equipment/maintenances/eq1',
      response: emptyList,
      call: (ApiClient api) =>
          EquipmentRepository(api).fetchMaintenances('eq1'),
    ),

    // ── Personal ─────────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/positions',
      response: emptyList,
      call: (ApiClient api) => PersonnelRepository(api).fetchPositions(),
    ),
    (
      method: 'POST',
      path: '/positions',
      response: emptyObject,
      call: (ApiClient api) =>
          PersonnelRepository(api).createPosition(position),
    ),
    (
      method: 'PUT',
      path: '/positions/pos1',
      response: emptyObject,
      call: (ApiClient api) =>
          PersonnelRepository(api).updatePosition(position),
    ),
    (
      method: 'DELETE',
      path: '/positions/pos1',
      response: null,
      call: (ApiClient api) => PersonnelRepository(api).deletePosition('pos1'),
    ),
    (
      method: 'GET',
      path: '/employees',
      response: emptyList,
      call: (ApiClient api) => PersonnelRepository(api).fetchEmployees(),
    ),
    (
      method: 'POST',
      path: '/employees',
      response: emptyObject,
      call: (ApiClient api) =>
          PersonnelRepository(api).createEmployee(employee),
    ),
    (
      method: 'PUT',
      path: '/employees/emp1',
      response: emptyObject,
      call: (ApiClient api) =>
          PersonnelRepository(api).updateEmployee(employee),
    ),
    (
      method: 'DELETE',
      path: '/employees/emp1',
      response: null,
      call: (ApiClient api) => PersonnelRepository(api).deleteEmployee('emp1'),
    ),
    (
      method: 'GET',
      path: '/contracts/p1',
      response: emptyList,
      call: (ApiClient api) => PersonnelRepository(api).fetchContracts('p1'),
    ),
    (
      method: 'POST',
      path: '/contracts',
      response: emptyObject,
      call: (ApiClient api) =>
          PersonnelRepository(api).createContract(laborContract),
    ),
    (
      method: 'PUT',
      path: '/contracts/lc1',
      response: emptyObject,
      call: (ApiClient api) =>
          PersonnelRepository(api).updateContract(laborContract),
    ),
    (
      method: 'DELETE',
      path: '/contracts/lc1',
      response: null,
      call: (ApiClient api) => PersonnelRepository(api).deleteContract('lc1'),
    ),

    // ── Asistencia ───────────────────────────────────────────────────────
    (
      method: 'POST',
      path: '/attendance',
      response: emptyObject,
      call: (ApiClient api) => AttendanceRepository(
        api,
      ).save(Attendance(projectId: 'p1', date: day)),
    ),
    (
      method: 'PUT',
      path: '/attendance/logs/l1',
      response: emptyObject,
      call: (ApiClient api) => AttendanceRepository(
        api,
      ).updateLog('l1', status: AttendanceStatus.present, hoursWorked: 8),
    ),
    (
      method: 'DELETE',
      path: '/attendance/at1',
      response: null,
      call: (ApiClient api) => AttendanceRepository(api).delete('at1'),
    ),

    // ── Contratistas ─────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/contractors',
      response: emptyList,
      call: (ApiClient api) => ContractorsRepository(api).fetchAll(),
    ),
    (
      method: 'POST',
      path: '/contractors',
      response: emptyObject,
      call: (ApiClient api) => ContractorsRepository(api).create(contractor),
    ),
    (
      method: 'PUT',
      path: '/contractors/ct1',
      response: emptyObject,
      call: (ApiClient api) => ContractorsRepository(api).update(contractor),
    ),
    (
      method: 'DELETE',
      path: '/contractors/ct1',
      response: null,
      call: (ApiClient api) => ContractorsRepository(api).delete('ct1'),
    ),
    (
      method: 'GET',
      path: '/contractors/contracts/p1',
      response: emptyList,
      call: (ApiClient api) => ContractorsRepository(api).fetchContracts('p1'),
    ),
    (
      method: 'POST',
      path: '/contractors/contracts',
      response: emptyObject,
      call: (ApiClient api) =>
          ContractorsRepository(api).createContract(contractorContract),
    ),
    (
      method: 'PUT',
      path: '/contractors/contracts/cc1',
      response: emptyObject,
      call: (ApiClient api) =>
          ContractorsRepository(api).updateContract(contractorContract),
    ),
    (
      method: 'DELETE',
      path: '/contractors/contracts/cc1',
      response: null,
      call: (ApiClient api) => ContractorsRepository(api).deleteContract('cc1'),
    ),
    (
      method: 'GET',
      path: '/contractors/payments',
      response: emptyList,
      call: (ApiClient api) => ContractorsRepository(api).fetchPayments(),
    ),
    (
      method: 'POST',
      path: '/contractors/payments',
      response: emptyObject,
      call: (ApiClient api) =>
          ContractorsRepository(api).registerPayment(contractorPayment),
    ),

    // ── Cronograma ───────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/schedule/p1',
      response: emptyList,
      call: (ApiClient api) => ScheduleRepository(api).fetchByProject('p1'),
    ),
    (
      method: 'POST',
      path: '/schedule/tasks',
      response: emptyObject,
      call: (ApiClient api) => ScheduleRepository(api).create(task),
    ),
    (
      method: 'PUT',
      path: '/schedule/tasks/t1',
      response: emptyObject,
      call: (ApiClient api) => ScheduleRepository(api).update(task),
    ),
    (
      method: 'DELETE',
      path: '/schedule/tasks/t1',
      response: null,
      call: (ApiClient api) => ScheduleRepository(api).delete('t1'),
    ),

    // ── Avance de obra ───────────────────────────────────────────────────
    (
      method: 'POST',
      path: '/progress/daily',
      response: emptyObject,
      call: (ApiClient api) => ProgressRepository(api).create(report),
    ),
    (
      method: 'PUT',
      path: '/progress/daily/r1',
      response: emptyObject,
      call: (ApiClient api) =>
          ProgressRepository(api).update('r1', observations: 'ok'),
    ),
    (
      method: 'DELETE',
      path: '/progress/daily/r1',
      response: null,
      call: (ApiClient api) => ProgressRepository(api).delete('r1'),
    ),

    // ── Fotos ────────────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/photos/p1',
      response: emptyList,
      call: (ApiClient api) => PhotosRepository(api).fetchByProject('p1'),
    ),
    (
      method: 'POST',
      path: '/photos',
      response: emptyObject,
      call: (ApiClient api) => PhotosRepository(api).create(photo),
    ),
    (
      method: 'PUT',
      path: '/photos/ph1',
      response: emptyObject,
      call: (ApiClient api) =>
          PhotosRepository(api).update('ph1', description: 'x'),
    ),
    (
      method: 'DELETE',
      path: '/photos/ph1',
      response: null,
      call: (ApiClient api) => PhotosRepository(api).delete('ph1'),
    ),

    // ── Facturación ──────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/invoices/project/p1',
      response: emptyList,
      call: (ApiClient api) => InvoicesRepository(api).fetchByProject('p1'),
    ),
    (
      method: 'GET',
      path: '/invoices/i1',
      response: emptyObject,
      call: (ApiClient api) => InvoicesRepository(api).fetchById('i1'),
    ),
    (
      method: 'POST',
      path: '/invoices',
      response: emptyObject,
      call: (ApiClient api) => InvoicesRepository(api).create(invoice),
    ),
    (
      method: 'PUT',
      path: '/invoices/i1',
      response: emptyObject,
      call: (ApiClient api) =>
          InvoicesRepository(api).update('i1', status: 'Issued'),
    ),
    (
      method: 'PATCH',
      path: '/invoices/i1/cancel',
      response: emptyObject,
      call: (ApiClient api) => InvoicesRepository(api).cancel('i1'),
    ),
    (
      method: 'DELETE',
      path: '/invoices/i1',
      response: null,
      call: (ApiClient api) => InvoicesRepository(api).delete('i1'),
    ),
    (
      method: 'GET',
      path: '/invoices/payments/i1',
      response: emptyList,
      call: (ApiClient api) => InvoicesRepository(api).fetchPayments('i1'),
    ),
    (
      method: 'POST',
      path: '/invoices/payments',
      response: emptyObject,
      call: (ApiClient api) => InvoicesRepository(api).registerPayment(payment),
    ),

    // ── Documentos ───────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/documents/types',
      response: emptyList,
      call: (ApiClient api) => DocumentsRepository(api).fetchTypes(),
    ),
    (
      method: 'POST',
      path: '/documents/types',
      response: emptyObject,
      call: (ApiClient api) =>
          DocumentsRepository(api).createType(name: 'Acta'),
    ),
    (
      method: 'PUT',
      path: '/documents/types/dt1',
      response: emptyObject,
      call: (ApiClient api) =>
          DocumentsRepository(api).updateType('dt1', name: 'Acta'),
    ),
    (
      method: 'DELETE',
      path: '/documents/types/dt1',
      response: null,
      call: (ApiClient api) => DocumentsRepository(api).deleteType('dt1'),
    ),
    (
      method: 'GET',
      path: '/documents/project/p1',
      response: emptyList,
      call: (ApiClient api) => DocumentsRepository(api).fetchByProject('p1'),
    ),
    (
      method: 'GET',
      path: '/documents/d1',
      response: emptyObject,
      call: (ApiClient api) => DocumentsRepository(api).fetchById('d1'),
    ),
    (
      method: 'POST',
      path: '/documents',
      response: emptyObject,
      call: (ApiClient api) => DocumentsRepository(api).create(
        projectId: 'p1',
        title: 'Acta de inicio',
        fileUrl: 'https://x/acta.pdf',
      ),
    ),
    (
      method: 'PUT',
      path: '/documents/d1',
      response: emptyObject,
      call: (ApiClient api) =>
          DocumentsRepository(api).update('d1', title: 'Acta'),
    ),
    (
      method: 'DELETE',
      path: '/documents/d1',
      response: null,
      call: (ApiClient api) => DocumentsRepository(api).delete('d1'),
    ),
    (
      method: 'GET',
      path: '/documents/versions/d1',
      response: emptyList,
      call: (ApiClient api) => DocumentsRepository(api).fetchVersions('d1'),
    ),
    (
      method: 'POST',
      path: '/documents/versions',
      response: emptyObject,
      call: (ApiClient api) => DocumentsRepository(api).addVersion(version),
    ),

    // ── Notificaciones ───────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/notifications',
      response: emptyList,
      call: (ApiClient api) => NotificationsRepository(api).fetchInbox(),
    ),
    (
      method: 'POST',
      path: '/notifications',
      response: emptyObject,
      call: (ApiClient api) => NotificationsRepository(
        api,
      ).create(notification, targetUsers: const <String>['u1']),
    ),
    (
      method: 'PATCH',
      path: '/notifications/n1/read',
      response: emptyObject,
      call: (ApiClient api) => NotificationsRepository(api).markAsRead('n1'),
    ),
    (
      method: 'DELETE',
      path: '/notifications/n1',
      response: null,
      call: (ApiClient api) => NotificationsRepository(api).delete('n1'),
    ),

    // ── Auditoría ────────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/audits-logs',
      response: emptyList,
      call: (ApiClient api) => AuditsRepository(api).fetchAll(),
    ),
    (
      method: 'POST',
      path: '/audits-logs',
      response: emptyObject,
      call: (ApiClient api) =>
          AuditsRepository(api).record(action: 'UPDATE', tableName: 'budgets'),
    ),

    // ── Suscripción ──────────────────────────────────────────────────────
    (
      method: 'GET',
      path: '/subscriptions/me',
      response: emptyObject,
      call: (ApiClient api) => SubscriptionsRepository(api).fetchMine(),
    ),
  ];

  group('Cada repositorio llama al endpoint documentado', () {
    for (final EndpointCase c in cases) {
      test('${c.method} ${c.path}', () async {
        final List<RecordedRequest> requests = <RecordedRequest>[];
        final ApiClient api = ApiClient(
          baseUrl: 'https://api.test',
          tokenProvider: () => 'jwt',
          httpClient: recordingClient(
            requests,
            (_) => jsonResponse(c.response),
          ),
        );

        await c.call(api);

        final RecordedRequest request = requests.single;
        expect(request.method, c.method);
        expect(request.url.path, c.path);
        expect(
          request.headers['authorization'],
          kPublicPaths.contains(c.path) ? isNull : 'Bearer jwt',
          reason: kPublicPaths.contains(c.path)
              ? 'es una ruta pública'
              : 'es una ruta protegida',
        );
      });
    }
  });

  test('no falta ningún endpoint por cubrir', () {
    // Red de seguridad: si se añade un repositorio y no se registra aquí, la
    // cuenta baja y la prueba avisa. `/login` se cubre aparte, en las pruebas
    // de autenticación.
    expect(cases, hasLength(112));
  });

  test('la app no expone alta de empresas ni acceso de superadministrador', () {
    // Estas rutas existen en el backend pero pertenecen a la web. Si alguien
    // las reintroduce en un repositorio, esta prueba lo caza.
    final Set<String> paths = cases.map((EndpointCase c) => c.path).toSet();
    expect(paths, isNot(contains('/register')));
    expect(paths, isNot(contains('/admin/login')));
    expect(
      paths.where((String p) => p.startsWith('/subscriptions')),
      <String>{'/subscriptions/me'},
      reason: 'el resto de /subscriptions es solo para superadministrador',
    );
  });

  group('Consultas con parámetro de fecha', () {
    test('GET /attendance/{project_id} manda date=YYYY-MM-DD', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ApiClient api = ApiClient(
        baseUrl: 'https://api.test',
        httpClient: recordingClient(
          requests,
          (_) => jsonResponse(<String, dynamic>{}),
        ),
      );

      await AttendanceRepository(api).fetchByDate('p1', DateTime(2026, 8, 8));

      expect(requests.single.url.path, '/attendance/p1');
      expect(requests.single.url.queryParameters['date'], '2026-08-08');
    });

    test('GET /progress/{project_id} manda date=YYYY-MM-DD', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ApiClient api = ApiClient(
        baseUrl: 'https://api.test',
        httpClient: recordingClient(
          requests,
          (_) => jsonResponse(<String, dynamic>{}),
        ),
      );

      await ProgressRepository(api).fetchByDate('p1', DateTime(2026, 8, 8));

      expect(requests.single.url.path, '/progress/p1');
      expect(requests.single.url.queryParameters['date'], '2026-08-08');
    });
  });

  group('Un 404 esperado no es un error', () {
    ApiClient notFoundClient() => ApiClient(
      baseUrl: 'https://api.test',
      httpClient: recordingClient(
        <RecordedRequest>[],
        (_) => textResponse('no encontrado', status: 404),
      ),
    );

    test('asistencia sin registrar devuelve null', () async {
      expect(
        await AttendanceRepository(notFoundClient()).fetchByDate('p1', day),
        isNull,
      );
    });

    test('día sin reporte de avance devuelve null', () async {
      expect(
        await ProgressRepository(notFoundClient()).fetchByDate('p1', day),
        isNull,
      );
    });

    test('empresa sin suscripción devuelve null', () async {
      expect(
        await SubscriptionsRepository(notFoundClient()).fetchMine(),
        isNull,
      );
    });
  });
}
