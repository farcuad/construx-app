import 'app_language.dart';
import 'app_strings.dart';
import 'sections/admin_strings.dart';
import 'sections/common_strings.dart';
import 'sections/finance_strings.dart';
import 'sections/resources_strings.dart';
import 'sections/site_strings.dart';

/// English copy.
const AppStrings kStringsEn = AppStrings(
  language: AppLanguage.en,
  moduleTitles: <String, String>{
    'projects': 'Projects',
    'clients': 'Clients',
    'budgets': 'Budgets',
    'expenses': 'Expenses',
    'purchases': 'Purchase orders',
    'suppliers': 'Suppliers',
    'inventory': 'Inventory',
    'equipment': 'Machinery',
    'personnel': 'Personnel',
    'attendance': 'Attendance',
    'contractors': 'Contractors',
    'schedule': 'Schedule',
    'progress': 'Site progress',
    'photos': 'Photos',
    'invoices': 'Invoicing',
    'documents': 'Documents',
    'users': 'Users',
    'audits': 'Audit log',
  },
  panel: 'Dashboard',
  brandSubtitle: 'SITE MANAGEMENT',
  openMenu: 'Open menu',
  refresh: 'Refresh',
  retry: 'Try again',
  somethingWentWrong: 'Something went wrong',
  cancel: 'Cancel',
  close: 'Close',
  unknownName: 'No name',
  noRole: 'No role',
  notices: 'Alerts',
  noticesEmptyTitle: 'All quiet',
  noticesEmptyMessage: 'You have no pending alerts.',
  noticesError: 'Alerts could not be loaded.',
  noticeMarkedRead: 'Alert marked as read',
  unreadOne: '1 unread alert',
  unreadMany: '{n} unread alerts',
  settings: 'Settings',
  settingsSession: 'Session',
  settingsPreferences: 'Preferences',
  settingsLegal: 'Legal',
  languageLabel: 'Language',
  languagePickerTitle: 'Choose a language',
  terms: 'Terms and conditions',
  termsIntro:
      'A summary of the terms for using Construx inside your company. The '
      'contract signed between your company and the service provider always '
      'takes precedence.',
  termsSections: <TermsSection>[
    (
      title: 'Using the app',
      body:
          'Construx is a work tool. Only people your company has issued '
          'credentials to may use it, and only to manage that company’s '
          'construction sites.',
    ),
    (
      title: 'Your account',
      body:
          'Credentials are personal and non-transferable. Everything done from '
          'your account is recorded under your name in the system audit log. '
          'If you believe someone else has access, tell your company '
          'administrator right away.',
    ),
    (
      title: 'The data you enter',
      body:
          'Expenses, progress reports, photos and any other information you '
          'enter belong to your company, which is responsible for that data. '
          'It is stored on its servers for as long as the contract lasts.',
    ),
    (
      title: 'Site photos',
      body:
          'Photos you upload are site records: they may be used as proof of '
          'progress, in reports and with clients. Avoid capturing people or '
          'documents unrelated to the work.',
    ),
    (
      title: 'Availability',
      body:
          'The service may be interrupted for maintenance or for reasons '
          'outside the provider’s control. Your company may revoke your '
          'access at any time, for instance when your employment ends.',
    ),
  ],
  logout: 'Sign out',
  logoutMessage: 'Sign out for real? Remembered credentials are kept.',
  logoutConfirm: 'Sign out',
  version: 'Version',
  common: kCommonEn,
  budgets: kBudgetsEn,
  expenses: kExpensesEn,
  purchases: kPurchasesEn,
  suppliers: kSuppliersEn,
  invoices: kInvoicesEn,
  schedule: kScheduleEn,
  progress: kProgressEn,
  attendance: kAttendanceEn,
  photos: kPhotosEn,
  contractors: kContractorsEn,
  day: kDayEn,
  inventory: kInventoryEn,
  equipment: kEquipmentEn,
  personnel: kPersonnelEn,
  documents: kDocumentsEn,
  projects: kProjectsEn,
  clients: kClientsEn,
  users: kUsersEn,
  audits: kAuditsEn,
  projectScope: kProjectScopeEn,
  dashboard: kDashboardEn,
  auth: kAuthEn,
);
