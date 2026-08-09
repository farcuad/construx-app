/// Catálogo de permisos del backend (tabla `permissions`).
///
/// Se usan constantes en lugar de literales para que un cambio de nombre en el
/// backend se corrija en un solo sitio y el analizador detecte typos.
abstract final class Perm {
  /// Comodín virtual presente solo en el JWT de los `Administrador`.
  static const String wildcard = '*';

  static const String usersRead = 'users:read';
  static const String usersCreate = 'users:create';
  static const String usersUpdate = 'users:update';
  static const String usersDelete = 'users:delete';

  static const String projectsCreate = 'projects:create';
  static const String projectsRead = 'projects:read';
  static const String projectsUpdate = 'projects:update';
  static const String projectsDelete = 'projects:delete';

  static const String clientsCreate = 'clients:create';
  static const String clientsRead = 'clients:read';
  static const String clientsUpdate = 'clients:update';
  static const String clientsDelete = 'clients:delete';

  static const String budgetsCreate = 'budgets:create';
  static const String budgetsRead = 'budgets:read';
  static const String budgetsUpdate = 'budgets:update';
  static const String budgetsDelete = 'budgets:delete';
  static const String budgetsApprove = 'budgets:approve';

  static const String expensesCreate = 'expenses:create';
  static const String expensesRead = 'expenses:read';
  static const String expensesUpdate = 'expenses:update';
  static const String expensesDelete = 'expenses:delete';

  static const String purchasesCreate = 'purchases:create';
  static const String purchasesRead = 'purchases:read';
  static const String purchasesUpdate = 'purchases:update';
  static const String purchasesDelete = 'purchases:delete';
  static const String purchasesApprove = 'purchases:approve';

  static const String suppliersCreate = 'suppliers:create';
  static const String suppliersRead = 'suppliers:read';
  static const String suppliersUpdate = 'suppliers:update';
  static const String suppliersDelete = 'suppliers:delete';

  static const String inventoryRead = 'inventory:read';
  static const String inventoryManage = 'inventory:manage';

  static const String equipmentRead = 'equipment:read';
  static const String equipmentManage = 'equipment:manage';
  static const String equipmentAssign = 'equipment:assign';

  static const String personnelRead = 'personnel:read';
  static const String personnelManage = 'personnel:manage';

  static const String attendanceRead = 'attendance:read';
  static const String attendanceMark = 'attendance:mark';

  static const String contractorsRead = 'contractors:read';
  static const String contractorsManage = 'contractors:manage';
  static const String contractorsPay = 'contractors:pay';

  static const String scheduleRead = 'schedule:read';
  static const String scheduleUpdate = 'schedule:update';

  static const String progressCreate = 'progress:create';
  static const String progressRead = 'progress:read';
  static const String progressUpdate = 'progress:update';
  static const String progressDelete = 'progress:delete';

  static const String photosUpload = 'photos:upload';
  static const String photosRead = 'photos:read';
  static const String photosDelete = 'photos:delete';

  static const String invoicesCreate = 'invoices:create';
  static const String invoicesRead = 'invoices:read';
  static const String invoicesUpdate = 'invoices:update';
  static const String invoicesDelete = 'invoices:delete';
  static const String invoicesCancel = 'invoices:cancel';
  static const String invoicesPay = 'invoices:pay';

  static const String dashboardRead = 'dashboard:read';

  static const String documentsCreate = 'documents:create';
  static const String documentsRead = 'documents:read';
  static const String documentsUpdate = 'documents:update';
  static const String documentsDelete = 'documents:delete';

  static const String notificationsRead = 'notifications:read';
  static const String notificationsManage = 'notifications:manage';

  static const String auditsRead = 'audits:read';
}
