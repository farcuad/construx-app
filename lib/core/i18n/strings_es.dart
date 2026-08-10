import 'app_language.dart';
import 'app_strings.dart';
import 'sections/admin_strings.dart';
import 'sections/common_strings.dart';
import 'sections/finance_strings.dart';
import 'sections/resources_strings.dart';
import 'sections/site_strings.dart';

/// Textos en español, el idioma de referencia: cuando haya dudas sobre qué
/// dice un texto, este es el original.
const AppStrings kStringsEs = AppStrings(
  language: AppLanguage.es,
  moduleTitles: <String, String>{
    'projects': 'Proyectos',
    'clients': 'Clientes',
    'budgets': 'Presupuestos',
    'expenses': 'Gastos',
    'purchases': 'Órdenes de compra',
    'suppliers': 'Proveedores',
    'inventory': 'Inventario',
    'equipment': 'Maquinaria',
    'personnel': 'Personal',
    'attendance': 'Asistencia',
    'contractors': 'Contratistas',
    'schedule': 'Cronograma',
    'progress': 'Avance de obra',
    'photos': 'Fotos',
    'invoices': 'Facturación',
    'documents': 'Documentos',
    'users': 'Usuarios',
    'audits': 'Auditoría',
  },
  panel: 'Panel',
  brandSubtitle: 'GESTIÓN DE OBRA',
  openMenu: 'Abrir menú',
  refresh: 'Actualizar',
  retry: 'Reintentar',
  somethingWentWrong: 'Algo salió mal',
  cancel: 'Cancelar',
  close: 'Cerrar',
  unknownName: 'Sin nombre',
  noRole: 'Sin rol',
  notices: 'Avisos',
  noticesEmptyTitle: 'Todo tranquilo',
  noticesEmptyMessage: 'No tienes avisos pendientes.',
  noticesError: 'No se pudieron cargar los avisos.',
  noticeMarkedRead: 'Aviso marcado como leído',
  unreadOne: '1 aviso sin leer',
  unreadMany: '{n} avisos sin leer',
  noticeChannelName: 'Avisos de obra',
  noticeChannelDescription:
      'Novedades de tus proyectos: presupuestos, tareas e incidencias.',
  offlineTitle: 'Sin conexión',
  offlineMessage:
      'Construx necesita internet para trabajar. Revisa el wifi o los datos '
      'móviles: en cuanto vuelva la señal seguirás donde lo dejaste.',
  offlineRestored: 'Conexión restablecida',
  settings: 'Ajustes',
  settingsSession: 'Sesión',
  settingsPreferences: 'Preferencias',
  settingsLegal: 'Legal',
  languageLabel: 'Idioma',
  languagePickerTitle: 'Elige un idioma',
  terms: 'Términos y condiciones',
  termsIntro:
      'Resumen de las condiciones de uso de Construx dentro de tu empresa. '
      'Prevalece siempre el contrato firmado entre tu empresa y el proveedor '
      'del servicio.',
  termsSections: <TermsSection>[
    (
      title: 'Uso de la aplicación',
      body:
          'Construx es una herramienta de trabajo. Solo pueden usarla las '
          'personas a las que su empresa ha dado credenciales, y únicamente '
          'para la gestión de las obras de esa empresa.',
    ),
    (
      title: 'Tu cuenta',
      body:
          'Las credenciales son personales e intransferibles. Todo lo que se '
          'haga desde tu cuenta queda registrado a tu nombre en la auditoría '
          'del sistema. Si crees que alguien más tiene acceso, avisa de '
          'inmediato al administrador de tu empresa.',
    ),
    (
      title: 'Datos que registras',
      body:
          'Los gastos, partes de avance, fotografías y demás información que '
          'introduces pertenecen a tu empresa, que es la responsable de esos '
          'datos. Se guardan en sus servidores y se conservan mientras dure '
          'la relación contractual.',
    ),
    (
      title: 'Fotografías de obra',
      body:
          'Las fotos que subes son documentación de obra: pueden usarse como '
          'prueba de avance, en informes y ante clientes. Evita capturar '
          'personas o documentos que no tengan que ver con el trabajo.',
    ),
    (
      title: 'Disponibilidad',
      body:
          'El servicio puede interrumpirse por mantenimiento o por causas '
          'ajenas al proveedor. Tu empresa puede revocar tu acceso en '
          'cualquier momento, por ejemplo al terminar tu relación laboral.',
    ),
  ],
  logout: 'Cerrar sesión',
  logoutMessage:
      '¿Seguro que quieres salir? Los datos recordados se conservan.',
  logoutConfirm: 'Salir',
  version: 'Versión',
  common: kCommonEs,
  budgets: kBudgetsEs,
  expenses: kExpensesEs,
  purchases: kPurchasesEs,
  suppliers: kSuppliersEs,
  invoices: kInvoicesEs,
  schedule: kScheduleEs,
  progress: kProgressEs,
  attendance: kAttendanceEs,
  photos: kPhotosEs,
  contractors: kContractorsEs,
  day: kDayEs,
  inventory: kInventoryEs,
  equipment: kEquipmentEs,
  personnel: kPersonnelEs,
  documents: kDocumentsEs,
  projects: kProjectsEs,
  clients: kClientsEs,
  users: kUsersEs,
  audits: kAuditsEs,
  projectScope: kProjectScopeEs,
  dashboard: kDashboardEs,
  auth: kAuthEs,
);
