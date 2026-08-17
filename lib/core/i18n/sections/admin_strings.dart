import 'package:flutter/foundation.dart';

import 'common_strings.dart';

/// Textos de proyectos, clientes, usuarios y auditoría, más los del selector de
/// obra que comparten todos los módulos.
@immutable
class ProjectsStrings {
  const ProjectsStrings({
    required this.loadError,
    required this.emptyTitle,
    required this.emptyCanCreate,
    required this.emptyReadOnly,
    required this.termElapsed,
    required this.edit,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.deleted,
    required this.notFoundTitle,
    required this.notFoundMessage,
    required this.fallbackTitle,
    required this.projectBudgetUpper,
    required this.unassigned,
    required this.expectedEnd,
    required this.noDashboardAccess,
    required this.financialSummary,
    required this.paidToProvidersShort,
    required this.varianceShort,
    required this.formNew,
    required this.formEdit,
    required this.name,
    required this.nameRequired,
    required this.noClients,
    required this.pickClient,
    required this.startDateHelp,
    required this.endDateHelp,
    required this.endBeforeStart,
    required this.undefined,
    required this.submit,
    required this.created,
    required this.updated,
  });

  final String loadError;
  final String emptyTitle;
  final String emptyCanCreate;
  final String emptyReadOnly;

  /// Porcentaje del plazo consumido: `{n}`.
  final String termElapsed;

  final String edit;
  final String deleteTitle;
  final String deleteMessage;
  final String deleted;
  final String notFoundTitle;
  final String notFoundMessage;

  /// Título de la barra del detalle cuando aún no se sabe el nombre.
  final String fallbackTitle;

  // Detalle de la obra.
  final String projectBudgetUpper;
  final String unassigned;
  final String expectedEnd;
  final String noDashboardAccess;
  final String financialSummary;
  final String paidToProvidersShort;
  final String varianceShort;

  // Formulario.
  final String formNew;
  final String formEdit;
  final String name;
  final String nameRequired;
  final String noClients;
  final String pickClient;
  final String startDateHelp;
  final String endDateHelp;
  final String endBeforeStart;
  final String undefined;
  final String submit;
  final String created;
  final String updated;

  String termElapsedOf(int percent) =>
      fill(termElapsed, <String, String>{'n': '$percent'});
  String deleteBody(String name) =>
      fill(deleteMessage, <String, String>{'n': name});
}

@immutable
class ClientsStrings {
  const ClientsStrings({
    required this.loadError,
    required this.emptyTitle,
    required this.emptyCanCreate,
    required this.emptyReadOnly,
    required this.taxId,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.deleted,
    required this.formNew,
    required this.formEdit,
    required this.name,
    required this.nameRequired,
    required this.taxIdField,
    required this.submit,
    required this.created,
    required this.updated,
  });

  final String loadError;
  final String emptyTitle;
  final String emptyCanCreate;
  final String emptyReadOnly;
  final String taxId;
  final String deleteTitle;
  final String deleteMessage;
  final String deleted;

  // Formulario.
  final String formNew;
  final String formEdit;
  final String name;
  final String nameRequired;
  final String taxIdField;
  final String submit;
  final String created;
  final String updated;

  String taxIdOf(String value) => fill(taxId, <String, String>{'v': value});
  String deleteBody(String name) =>
      fill(deleteMessage, <String, String>{'n': name});
}

@immutable
class UsersStrings {
  const UsersStrings({
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.fullAccess,
    required this.permissionsCount,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.deleted,
  });

  final String loadError;
  final String emptyTitle;
  final String emptyMessage;

  /// Lo que se muestra para el permiso comodín.
  final String fullAccess;

  /// Cuántos permisos tiene: `{n}`.
  final String permissionsCount;

  final String deleteTitle;
  final String deleteMessage;
  final String deleted;

  String permissions(int n) =>
      fill(permissionsCount, <String, String>{'n': '$n'});
  String deleteBody(String name) =>
      fill(deleteMessage, <String, String>{'n': name});
}

@immutable
class AuditsStrings {
  const AuditsStrings({
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.changedOne,
    required this.changedMany,
    required this.before,
    required this.after,
    required this.moreOne,
    required this.moreMany,
    required this.noFields,
  });

  final String loadError;
  final String emptyTitle;
  final String emptyMessage;
  final String changedOne;
  final String changedMany;

  /// Rótulo del valor anterior en el comparativo de cada campo.
  final String before;

  /// Rótulo del valor nuevo en el comparativo de cada campo.
  final String after;

  /// Campos que quedan fuera del mini cuadro: `{n}`.
  final String moreOne;
  final String moreMany;

  /// Cuando la entrada no trae valores que comparar (`noFields`).
  final String noFields;

  String changed(int n) => plural(n, changedOne, changedMany);
  String more(int n) => plural(n, moreOne, moreMany);
}

/// Desplegable de obra y el envoltorio que usan los módulos por obra.
@immutable
class ProjectScopeStrings {
  const ProjectScopeStrings({
    required this.label,
    required this.hint,
    required this.loadError,
    required this.emptyTitle,
    required this.defaultEmptyMessage,
    required this.goToProjects,
  });

  /// Rótulo pequeño encima del nombre de la obra.
  final String label;

  final String hint;
  final String loadError;
  final String emptyTitle;
  final String defaultEmptyMessage;
  final String goToProjects;
}

/// Panel financiero.
@immutable
class DashboardStrings {
  const DashboardStrings({
    required this.projectsError,
    required this.kpisError,
    required this.noProjectsMessage,
    required this.noAccessTitle,
    required this.noAccessMessage,
    required this.budgetUsed,
    required this.noBudget,
    required this.committed,
    required this.overBudget,
    required this.totalBudget,
    required this.expenses,
    required this.purchases,
    required this.invoiced,
    required this.collected,
    required this.pendingToCollect,
    required this.allCollected,
    required this.paidToProviders,
    required this.variance,
    required this.inFavour,
    required this.against,
    required this.totalSpent,
    required this.collectedVsInvoiced,
    required this.trendTitle,
    required this.categoriesTitle,
    required this.noTrendData,
    required this.noExpenses,
  });

  final String projectsError;
  final String kpisError;
  final String noProjectsMessage;
  final String noAccessTitle;
  final String noAccessMessage;
  final String budgetUsed;
  final String noBudget;
  final String committed;

  /// Cuánto se pasa del presupuesto: `{a}`.
  final String overBudget;

  final String totalBudget;
  final String expenses;
  final String purchases;
  final String invoiced;
  final String collected;

  /// Pendiente de cobro: `{a}`.
  final String pendingToCollect;

  final String allCollected;
  final String paidToProviders;
  final String variance;
  final String inFavour;
  final String against;

  // Gráficos del panel: tarjetas clave y títulos de sección.
  final String totalSpent;
  final String collectedVsInvoiced;
  final String trendTitle;
  final String categoriesTitle;
  final String noTrendData;
  final String noExpenses;

  String overBudgetBy(String amount) =>
      fill(overBudget, <String, String>{'a': amount});
  String pendingOf(String amount) =>
      fill(pendingToCollect, <String, String>{'a': amount});
}

/// Pantalla de acceso.
@immutable
class AuthStrings {
  const AuthStrings({
    required this.tagline,
    required this.emailHint,
    required this.password,
    required this.rememberMe,
    required this.signIn,
    required this.showPassword,
    required this.hidePassword,
    required this.welcomeBack,
    required this.footer,
  });

  final String tagline;
  final String emailHint;
  final String password;
  final String rememberMe;
  final String signIn;
  final String showPassword;
  final String hidePassword;

  /// Confirmación tras entrar.
  final String welcomeBack;

  final String footer;
}

// ─────────────────────────────── español ────────────────────────────────

const ProjectsStrings kProjectsEs = ProjectsStrings(
  loadError: 'No se pudieron cargar los proyectos.',
  emptyTitle: 'Aún no hay proyectos',
  emptyCanCreate:
      'Crea el primero para empezar a registrar avances, gastos y presupuestos.',
  emptyReadOnly: 'Cuando tu empresa registre obras, aparecerán aquí.',
  termElapsed: '{n}% del plazo',
  edit: 'Editar',
  deleteTitle: 'Eliminar proyecto',
  deleteMessage: 'Se eliminará «{n}». Esta acción no se puede deshacer.',
  deleted: 'Proyecto eliminado',
  notFoundTitle: 'Proyecto no encontrado',
  notFoundMessage: 'Puede que se haya eliminado o que no tengas acceso.',
  fallbackTitle: 'Proyecto',
  projectBudgetUpper: 'PRESUPUESTO DEL PROYECTO',
  unassigned: 'Sin asignar',
  expectedEnd: 'Fin previsto',
  noDashboardAccess: 'Tu rol no tiene acceso al dashboard financiero.',
  financialSummary: 'Resumen financiero',
  paidToProvidersShort: 'Pagado a prov.',
  varianceShort: 'Variación',
  formNew: 'Nuevo proyecto',
  formEdit: 'Editar proyecto',
  name: 'Nombre del proyecto',
  nameRequired: 'Ingresa el nombre de la obra',
  noClients: 'No hay clientes registrados',
  pickClient: 'Selecciona un cliente',
  startDateHelp: 'Fecha de inicio',
  endDateHelp: 'Fecha de fin',
  endBeforeStart: 'La fecha de fin debe ser posterior al inicio.',
  undefined: 'Sin definir',
  submit: 'Crear proyecto',
  created: 'Proyecto creado',
  updated: 'Proyecto actualizado',
);

const ClientsStrings kClientsEs = ClientsStrings(
  loadError: 'No se pudieron cargar los clientes.',
  emptyTitle: 'Aún no hay clientes',
  emptyCanCreate:
      'Registra tu primer cliente para poder asociarlo a un proyecto.',
  emptyReadOnly: 'Cuando tu empresa registre clientes, aparecerán aquí.',
  taxId: 'NIT {v}',
  deleteTitle: 'Eliminar cliente',
  deleteMessage: 'Se eliminará «{n}».',
  deleted: 'Cliente eliminado',
  formNew: 'Nuevo cliente',
  formEdit: 'Editar cliente',
  name: 'Nombre o razón social',
  nameRequired: 'Ingresa el nombre',
  taxIdField: 'NIT / Documento',
  submit: 'Crear cliente',
  created: 'Cliente creado',
  updated: 'Cliente actualizado',
);

const UsersStrings kUsersEs = UsersStrings(
  loadError: 'No se pudieron cargar los usuarios.',
  emptyTitle: 'Sin usuarios',
  emptyMessage: 'Tu empresa aún no tiene otros usuarios dados de alta.',
  fullAccess: 'Acceso total (*)',
  permissionsCount: '{n} permisos',
  deleteTitle: 'Eliminar usuario',
  deleteMessage: 'Se eliminará «{n}» y perderá el acceso a la app.',
  deleted: 'Usuario eliminado',
);

const AuditsStrings kAuditsEs = AuditsStrings(
  loadError: 'No se pudo cargar el registro de auditoría.',
  emptyTitle: 'Sin movimientos registrados',
  emptyMessage:
      'Aquí queda constancia de quién crea, modifica o elimina información '
      'en el sistema.',
  changedOne: '1 campo con valor nuevo',
  changedMany: '{n} campos con valor nuevo',
  before: 'Antes',
  after: 'Después',
  moreOne: 'y 1 campo más',
  moreMany: 'y {n} campos más',
  noFields: 'Sin datos de la fila afectada',
);

const ProjectScopeStrings kProjectScopeEs = ProjectScopeStrings(
  label: 'PROYECTO',
  hint: 'Elige una obra',
  loadError: 'No se pudieron cargar los proyectos.',
  emptyTitle: 'Aún no hay proyectos',
  defaultEmptyMessage:
      'Este módulo trabaja sobre una obra. Crea la primera para empezar.',
  goToProjects: 'Ir a proyectos',
);

const DashboardStrings kDashboardEs = DashboardStrings(
  projectsError: 'No se pudieron cargar los proyectos.',
  kpisError: 'No se pudieron cargar los indicadores.',
  noProjectsMessage:
      'Los indicadores financieros se calculan por obra. Crea la primera para '
      'empezar a verlos aquí.',
  noAccessTitle: 'Sin acceso al tablero',
  noAccessMessage:
      'Tu rol no tiene el permiso «dashboard:read». Pídeselo al administrador '
      'de tu empresa para ver los indicadores.',
  budgetUsed: 'Presupuesto consumido',
  noBudget: 'Sin presupuesto',
  committed: 'Comprometido',
  overBudget: 'Sobrepasa el presupuesto en {a}',
  totalBudget: 'Presupuesto total',
  expenses: 'Gastos',
  purchases: 'Compras',
  invoiced: 'Facturado',
  collected: 'Cobrado',
  pendingToCollect: 'Pendiente {a}',
  allCollected: 'Todo cobrado',
  paidToProviders: 'Pagado a proveedores',
  variance: 'Variación financiera',
  inFavour: 'A favor',
  against: 'En contra',
  totalSpent: 'Total gastado',
  collectedVsInvoiced: 'Cobrado vs. facturado',
  trendTitle: 'Tendencia financiera',
  categoriesTitle: 'Gastos por categoría',
  noTrendData: 'Sin datos de tendencia para este proyecto.',
  noExpenses: 'Sin gastos registrados.',
);

const AuthStrings kAuthEs = AuthStrings(
  tagline: 'Gestiona obras, presupuestos y equipos\ndesde un solo lugar',
  emailHint: 'tucorreo@empresa.com',
  password: 'Contraseña',
  rememberMe: 'Recordar datos',
  signIn: 'Iniciar sesión',
  showPassword: 'Mostrar contraseña',
  hidePassword: 'Ocultar contraseña',
  welcomeBack: 'Bienvenido de nuevo',
  footer: 'Conexión segura · Datos cifrados en el dispositivo',
);

// ────────────────────────────── português ───────────────────────────────

const ProjectsStrings kProjectsPt = ProjectsStrings(
  loadError: 'Não foi possível carregar as obras.',
  emptyTitle: 'Ainda não há obras',
  emptyCanCreate:
      'Crie a primeira para começar a registrar andamento, despesas e '
      'orçamentos.',
  emptyReadOnly: 'Quando a sua empresa cadastrar obras, elas aparecerão aqui.',
  termElapsed: '{n}% do prazo',
  edit: 'Editar',
  deleteTitle: 'Excluir obra',
  deleteMessage: '«{n}» será excluída. Esta ação não pode ser desfeita.',
  deleted: 'Obra excluída',
  notFoundTitle: 'Obra não encontrada',
  notFoundMessage: 'Pode ter sido excluída ou você não tem acesso.',
  fallbackTitle: 'Obra',
  projectBudgetUpper: 'ORÇAMENTO DA OBRA',
  unassigned: 'Não atribuído',
  expectedEnd: 'Fim previsto',
  noDashboardAccess: 'O seu cargo não tem acesso ao painel financeiro.',
  financialSummary: 'Resumo financeiro',
  paidToProvidersShort: 'Pago a forn.',
  varianceShort: 'Variação',
  formNew: 'Nova obra',
  formEdit: 'Editar obra',
  name: 'Nome da obra',
  nameRequired: 'Informe o nome da obra',
  noClients: 'Não há clientes cadastrados',
  pickClient: 'Selecione um cliente',
  startDateHelp: 'Data de início',
  endDateHelp: 'Data de fim',
  endBeforeStart: 'A data de fim deve ser posterior ao início.',
  undefined: 'Não definido',
  submit: 'Criar obra',
  created: 'Obra criada',
  updated: 'Obra atualizada',
);

const ClientsStrings kClientsPt = ClientsStrings(
  loadError: 'Não foi possível carregar os clientes.',
  emptyTitle: 'Ainda não há clientes',
  emptyCanCreate:
      'Cadastre o seu primeiro cliente para poder vinculá-lo a uma obra.',
  emptyReadOnly:
      'Quando a sua empresa cadastrar clientes, eles aparecerão aqui.',
  taxId: 'CNPJ {v}',
  deleteTitle: 'Excluir cliente',
  deleteMessage: '«{n}» será excluído.',
  deleted: 'Cliente excluído',
  formNew: 'Novo cliente',
  formEdit: 'Editar cliente',
  name: 'Nome ou razão social',
  nameRequired: 'Informe o nome',
  taxIdField: 'CNPJ / Documento',
  submit: 'Criar cliente',
  created: 'Cliente criado',
  updated: 'Cliente atualizado',
);

const UsersStrings kUsersPt = UsersStrings(
  loadError: 'Não foi possível carregar os usuários.',
  emptyTitle: 'Sem usuários',
  emptyMessage: 'A sua empresa ainda não tem outros usuários cadastrados.',
  fullAccess: 'Acesso total (*)',
  permissionsCount: '{n} permissões',
  deleteTitle: 'Excluir usuário',
  deleteMessage: '«{n}» será excluído e perderá o acesso ao aplicativo.',
  deleted: 'Usuário excluído',
);

const AuditsStrings kAuditsPt = AuditsStrings(
  loadError: 'Não foi possível carregar o registro de auditoria.',
  emptyTitle: 'Sem movimentações registradas',
  emptyMessage:
      'Aqui fica o registro de quem cria, altera ou exclui informação no '
      'sistema.',
  changedOne: '1 campo com valor novo',
  changedMany: '{n} campos com valor novo',
  before: 'Antes',
  after: 'Depois',
  moreOne: 'e mais 1 campo',
  moreMany: 'e mais {n} campos',
  noFields: 'Sem dados da linha afetada',
);

const ProjectScopeStrings kProjectScopePt = ProjectScopeStrings(
  label: 'OBRA',
  hint: 'Escolha uma obra',
  loadError: 'Não foi possível carregar as obras.',
  emptyTitle: 'Ainda não há obras',
  defaultEmptyMessage:
      'Este módulo trabalha sobre uma obra. Crie a primeira para começar.',
  goToProjects: 'Ir para obras',
);

const DashboardStrings kDashboardPt = DashboardStrings(
  projectsError: 'Não foi possível carregar as obras.',
  kpisError: 'Não foi possível carregar os indicadores.',
  noProjectsMessage:
      'Os indicadores financeiros são calculados por obra. Crie a primeira '
      'para começar a vê-los aqui.',
  noAccessTitle: 'Sem acesso ao painel',
  noAccessMessage:
      'O seu cargo não tem a permissão «dashboard:read». Peça-a ao '
      'administrador da sua empresa para ver os indicadores.',
  budgetUsed: 'Orçamento consumido',
  noBudget: 'Sem orçamento',
  committed: 'Comprometido',
  overBudget: 'Ultrapassa o orçamento em {a}',
  totalBudget: 'Orçamento total',
  expenses: 'Despesas',
  purchases: 'Compras',
  invoiced: 'Faturado',
  collected: 'Recebido',
  pendingToCollect: 'Pendente {a}',
  allCollected: 'Tudo recebido',
  paidToProviders: 'Pago a fornecedores',
  variance: 'Variação financeira',
  inFavour: 'A favor',
  against: 'Contra',
  totalSpent: 'Gasto total',
  collectedVsInvoiced: 'Recebido vs. faturado',
  trendTitle: 'Tendência financeira',
  categoriesTitle: 'Despesas por categoria',
  noTrendData: 'Sem dados de tendência para este projeto.',
  noExpenses: 'Sem despesas registradas.',
);

const AuthStrings kAuthPt = AuthStrings(
  tagline: 'Gerencie obras, orçamentos e equipes\nem um só lugar',
  emailHint: 'seuemail@empresa.com',
  password: 'Senha',
  rememberMe: 'Lembrar dados',
  signIn: 'Entrar',
  showPassword: 'Mostrar senha',
  hidePassword: 'Ocultar senha',
  welcomeBack: 'Bem-vindo de volta',
  footer: 'Conexão segura · Dados criptografados no aparelho',
);

// ─────────────────────────────── english ────────────────────────────────

const ProjectsStrings kProjectsEn = ProjectsStrings(
  loadError: 'Projects could not be loaded.',
  emptyTitle: 'No projects yet',
  emptyCanCreate:
      'Create the first one to start recording progress, expenses and '
      'budgets.',
  emptyReadOnly: 'Once your company registers sites, they will show up here.',
  termElapsed: '{n}% of the schedule',
  edit: 'Edit',
  deleteTitle: 'Delete project',
  deleteMessage: '“{n}” will be deleted. This cannot be undone.',
  deleted: 'Project deleted',
  notFoundTitle: 'Project not found',
  notFoundMessage: 'It may have been deleted, or you may not have access.',
  fallbackTitle: 'Project',
  projectBudgetUpper: 'PROJECT BUDGET',
  unassigned: 'Unassigned',
  expectedEnd: 'Expected end',
  noDashboardAccess: 'Your role has no access to the financial dashboard.',
  financialSummary: 'Financial summary',
  paidToProvidersShort: 'Paid to suppl.',
  varianceShort: 'Variance',
  formNew: 'New project',
  formEdit: 'Edit project',
  name: 'Project name',
  nameRequired: 'Enter the site name',
  noClients: 'No clients registered',
  pickClient: 'Choose a client',
  startDateHelp: 'Start date',
  endDateHelp: 'End date',
  endBeforeStart: 'The end date must come after the start date.',
  undefined: 'Not set',
  submit: 'Create project',
  created: 'Project created',
  updated: 'Project updated',
);

const ClientsStrings kClientsEn = ClientsStrings(
  loadError: 'Clients could not be loaded.',
  emptyTitle: 'No clients yet',
  emptyCanCreate: 'Add your first client so you can link them to a project.',
  emptyReadOnly: 'Once your company registers clients, they will show up here.',
  taxId: 'Tax ID {v}',
  deleteTitle: 'Delete client',
  deleteMessage: '“{n}” will be deleted.',
  deleted: 'Client deleted',
  formNew: 'New client',
  formEdit: 'Edit client',
  name: 'Name or legal name',
  nameRequired: 'Enter the name',
  taxIdField: 'Tax ID / Document',
  submit: 'Create client',
  created: 'Client created',
  updated: 'Client updated',
);

const UsersStrings kUsersEn = UsersStrings(
  loadError: 'Users could not be loaded.',
  emptyTitle: 'No users',
  emptyMessage: 'Your company has no other users registered yet.',
  fullAccess: 'Full access (*)',
  permissionsCount: '{n} permissions',
  deleteTitle: 'Delete user',
  deleteMessage: '“{n}” will be deleted and will lose access to the app.',
  deleted: 'User deleted',
);

const AuditsStrings kAuditsEn = AuditsStrings(
  loadError: 'The audit log could not be loaded.',
  emptyTitle: 'No activity recorded',
  emptyMessage:
      'This is the record of who creates, changes or deletes information in '
      'the system.',
  changedOne: '1 field with a new value',
  changedMany: '{n} fields with new values',
  before: 'Before',
  after: 'After',
  moreOne: 'and 1 more field',
  moreMany: 'and {n} more fields',
  noFields: 'No data for the affected row',
);

const ProjectScopeStrings kProjectScopeEn = ProjectScopeStrings(
  label: 'PROJECT',
  hint: 'Choose a site',
  loadError: 'Projects could not be loaded.',
  emptyTitle: 'No projects yet',
  defaultEmptyMessage:
      'This module works on a site. Create the first one to get started.',
  goToProjects: 'Go to projects',
);

const DashboardStrings kDashboardEn = DashboardStrings(
  projectsError: 'Projects could not be loaded.',
  kpisError: 'The figures could not be loaded.',
  noProjectsMessage:
      'Financial figures are calculated per site. Create the first one to '
      'start seeing them here.',
  noAccessTitle: 'No access to the dashboard',
  noAccessMessage:
      'Your role lacks the “dashboard:read” permission. Ask your company '
      'administrator for it to see the figures.',
  budgetUsed: 'Budget used',
  noBudget: 'No budget',
  committed: 'Committed',
  overBudget: 'Over budget by {a}',
  totalBudget: 'Total budget',
  expenses: 'Expenses',
  purchases: 'Purchases',
  invoiced: 'Invoiced',
  collected: 'Collected',
  pendingToCollect: 'Outstanding {a}',
  allCollected: 'All collected',
  paidToProviders: 'Paid to suppliers',
  variance: 'Financial variance',
  inFavour: 'In your favour',
  against: 'Against you',
  totalSpent: 'Total spent',
  collectedVsInvoiced: 'Collected vs. invoiced',
  trendTitle: 'Financial trend',
  categoriesTitle: 'Expenses by category',
  noTrendData: 'No trend data for this project.',
  noExpenses: 'No expenses recorded.',
);

const AuthStrings kAuthEn = AuthStrings(
  tagline: 'Run sites, budgets and crews\nfrom one place',
  emailHint: 'you@company.com',
  password: 'Password',
  rememberMe: 'Remember me',
  signIn: 'Sign in',
  showPassword: 'Show password',
  hidePassword: 'Hide password',
  welcomeBack: 'Welcome back',
  footer: 'Secure connection · Data encrypted on the device',
);
