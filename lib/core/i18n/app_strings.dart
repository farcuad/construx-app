import 'package:flutter/foundation.dart';

import 'app_language.dart';
import 'sections/admin_strings.dart';
import 'sections/common_strings.dart';
import 'sections/finance_strings.dart';
import 'sections/resources_strings.dart';
import 'sections/site_strings.dart';

/// Un apartado de los términos y condiciones: título y cuerpo.
typedef TermsSection = ({String title, String body});

/// Textos de la interfaz en un idioma.
///
/// Es una clase con campos, no un mapa de claves: así el compilador avisa si
/// se añade un texto y se olvida traducirlo, en vez de aparecer una cadena
/// vacía en pantalla. Las tres instancias viven en `strings_es/pt/en.dart`.
///
/// Cubre el **armazón** de la app —menú, barra inferior, avisos, ajustes— que
/// es lo que se navega en cualquier idioma. El contenido de cada módulo sigue
/// en español; se irá trayendo aquí módulo a módulo.
@immutable
class AppStrings {
  const AppStrings({
    required this.language,
    required this.moduleTitles,
    required this.panel,
    required this.brandSubtitle,
    required this.openMenu,
    required this.refresh,
    required this.retry,
    required this.somethingWentWrong,
    required this.cancel,
    required this.close,
    required this.unknownName,
    required this.noRole,
    required this.notices,
    required this.noticesEmptyTitle,
    required this.noticesEmptyMessage,
    required this.noticesError,
    required this.noticeMarkedRead,
    required this.unreadOne,
    required this.unreadMany,
    required this.settings,
    required this.settingsSession,
    required this.settingsPreferences,
    required this.settingsLegal,
    required this.languageLabel,
    required this.languagePickerTitle,
    required this.terms,
    required this.termsIntro,
    required this.termsSections,
    required this.logout,
    required this.logoutMessage,
    required this.logoutConfirm,
    required this.version,
    required this.common,
    required this.budgets,
    required this.expenses,
    required this.purchases,
    required this.suppliers,
    required this.invoices,
    required this.schedule,
    required this.progress,
    required this.attendance,
    required this.photos,
    required this.contractors,
    required this.day,
    required this.inventory,
    required this.equipment,
    required this.personnel,
    required this.documents,
    required this.projects,
    required this.clients,
    required this.users,
    required this.audits,
    required this.projectScope,
    required this.dashboard,
    required this.auth,
  });

  final AppLanguage language;

  // Textos por módulo. Cada grupo vive en `sections/`, con sus tres idiomas
  // juntos, que es como resulta cómodo mantenerlos.
  final CommonStrings common;
  final BudgetsStrings budgets;
  final ExpensesStrings expenses;
  final PurchasesStrings purchases;
  final SuppliersStrings suppliers;
  final InvoicesStrings invoices;
  final ScheduleStrings schedule;
  final ProgressStrings progress;
  final AttendanceStrings attendance;
  final PhotosStrings photos;
  final ContractorsStrings contractors;
  final DayStrings day;
  final InventoryStrings inventory;
  final EquipmentStrings equipment;
  final PersonnelStrings personnel;
  final DocumentsStrings documents;
  final ProjectsStrings projects;
  final ClientsStrings clients;
  final UsersStrings users;
  final AuditsStrings audits;
  final ProjectScopeStrings projectScope;
  final DashboardStrings dashboard;
  final AuthStrings auth;

  /// Título de cada módulo, indexado por su id en el catálogo. Se consulta con
  /// [module], que resuelve la falta de traducción.
  final Map<String, String> moduleTitles;

  // Armazón.
  final String panel;
  final String brandSubtitle;
  final String openMenu;
  final String refresh;
  final String retry;
  final String somethingWentWrong;
  final String cancel;
  final String close;
  final String unknownName;
  final String noRole;

  // Avisos.
  final String notices;
  final String noticesEmptyTitle;
  final String noticesEmptyMessage;
  final String noticesError;
  final String noticeMarkedRead;
  final String unreadOne;

  /// Plural con `{n}` como hueco para la cifra.
  final String unreadMany;

  // Ajustes.
  final String settings;
  final String settingsSession;
  final String settingsPreferences;
  final String settingsLegal;
  final String languageLabel;
  final String languagePickerTitle;
  final String terms;
  final String termsIntro;
  final List<TermsSection> termsSections;
  final String logout;
  final String logoutMessage;
  final String logoutConfirm;
  final String version;

  /// Título del módulo [id]; si falta la traducción se devuelve [fallback],
  /// que es el título en español del catálogo.
  String module(String id, [String fallback = '']) =>
      moduleTitles[id] ?? fallback;

  /// Rótulo del distintivo de la campana: «3 avisos sin leer».
  String unreadNotices(int count) =>
      count == 1 ? unreadOne : unreadMany.replaceFirst('{n}', '$count');
}
