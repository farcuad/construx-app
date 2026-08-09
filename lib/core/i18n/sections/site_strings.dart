import 'package:flutter/foundation.dart';

import 'common_strings.dart';

/// Textos de los módulos que se usan a pie de obra: cronograma, avance,
/// asistencia, fotos y contratistas.
@immutable
class ScheduleStrings {
  const ScheduleStrings({
    required this.needsProject,
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.overallProgress,
    required this.doneOfTotal,
    required this.doneOfOne,
    required this.untitled,
    required this.late,
  });

  final String needsProject;
  final String loadError;
  final String emptyTitle;
  final String emptyMessage;
  final String overallProgress;

  /// Resumen del avance: `{d}` terminadas de `{n}`.
  final String doneOfTotal;

  /// La misma frase cuando solo hay una tarea, para no decir «de 1 tareas».
  final String doneOfOne;

  final String untitled;
  final String late;

  String emptyFor(String project) =>
      fill(emptyMessage, <String, String>{'p': project});
  String progressOf(int done, int total) => fill(
    total == 1 ? doneOfOne : doneOfTotal,
    <String, String>{'d': '$done', 'n': '$total'},
  );
}

@immutable
class ProgressStrings {
  const ProgressStrings({
    required this.needsProject,
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.reportOfDayUpper,
    required this.unnamedTask,
    required this.executed,
  });

  final String needsProject;
  final String loadError;
  final String emptyTitle;
  final String emptyMessage;
  final String reportOfDayUpper;
  final String unnamedTask;

  /// Cantidad ejecutada: `{q}`.
  final String executed;

  String executedOf(String quantity) =>
      fill(executed, <String, String>{'q': quantity});
}

@immutable
class AttendanceStrings {
  const AttendanceStrings({
    required this.needsProject,
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.presentUpper,
    required this.rateUpper,
    required this.hoursUpper,
    required this.ofTotal,
    required this.hourSuffix,
    required this.unnamedEmployee,
    required this.statuses,
  });

  final String needsProject;
  final String loadError;
  final String emptyTitle;
  final String emptyMessage;
  final String presentUpper;
  final String rateUpper;
  final String hoursUpper;

  /// «3 de 8»: `{a}` de `{b}`.
  final String ofTotal;

  /// Abreviatura de hora que acompaña a la cifra.
  final String hourSuffix;

  final String unnamedEmployee;

  /// Estados de asistencia, indexados por el valor exacto de la API
  /// (`Present`, `Absent`, `Late`, `Justified Absence`). Se indexa por ahí y no
  /// por el `enum` para no meter una dependencia de `features` dentro de
  /// `core`.
  final Map<String, String> statuses;

  String countOf(int a, int b) =>
      fill(ofTotal, <String, String>{'a': '$a', 'b': '$b'});
  String status(String apiValue, String fallback) =>
      statuses[apiValue] ?? fallback;
}

@immutable
class PhotosStrings {
  const PhotosStrings({
    required this.needsProject,
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.deleted,
  });

  final String needsProject;
  final String loadError;
  final String emptyTitle;
  final String emptyMessage;
  final String deleteTitle;
  final String deleteMessage;
  final String deleted;

  String emptyFor(String project) =>
      fill(emptyMessage, <String, String>{'p': project});
}

@immutable
class ContractorsStrings {
  const ContractorsStrings({
    required this.tabCompanies,
    required this.tabContracts,
    required this.tabPayments,
    required this.companiesError,
    required this.companiesEmptyTitle,
    required this.companiesEmptyMessage,
    required this.taxId,
    required this.needsProject,
    required this.contractsError,
    required this.contractsEmptyTitle,
    required this.contractsEmptyMessage,
    required this.untitledContract,
    required this.paymentsError,
    required this.paymentsEmptyTitle,
    required this.paymentsEmptyMessage,
  });

  final String tabCompanies;
  final String tabContracts;
  final String tabPayments;
  final String companiesError;
  final String companiesEmptyTitle;
  final String companiesEmptyMessage;
  final String taxId;
  final String needsProject;
  final String contractsError;
  final String contractsEmptyTitle;
  final String contractsEmptyMessage;
  final String untitledContract;
  final String paymentsError;
  final String paymentsEmptyTitle;
  final String paymentsEmptyMessage;

  String taxIdOf(String value) => fill(taxId, <String, String>{'v': value});
  String contractsEmptyFor(String project) =>
      fill(contractsEmptyMessage, <String, String>{'p': project});
}

/// Barra de días compartida por avance y asistencia.
@immutable
class DayStrings {
  const DayStrings({
    required this.previous,
    required this.next,
    required this.todayUpper,
    required this.dateUpper,
  });

  final String previous;
  final String next;
  final String todayUpper;
  final String dateUpper;
}

// ─────────────────────────────── español ────────────────────────────────

const ScheduleStrings kScheduleEs = ScheduleStrings(
  needsProject: 'El cronograma se planifica por obra.',
  loadError: 'No se pudo cargar el cronograma.',
  emptyTitle: 'Sin tareas',
  emptyMessage: '«{p}» no tiene tareas planificadas.',
  overallProgress: 'Avance del cronograma',
  doneOfTotal: '{d} de {n} tareas terminadas',
  doneOfOne: '{d} de 1 tarea terminada',
  untitled: 'Tarea',
  late: 'Atrasada',
);

const ProgressStrings kProgressEs = ProgressStrings(
  needsProject: 'El avance se reporta por obra.',
  loadError: 'No se pudo cargar el reporte del día.',
  emptyTitle: 'Sin reporte ese día',
  emptyMessage:
      'No se registró avance en la fecha elegida. Prueba con otro día.',
  reportOfDayUpper: 'REPORTE DEL DÍA',
  unnamedTask: 'Tarea',
  executed: 'Ejecutado: {q}',
);

const AttendanceStrings kAttendanceEs = AttendanceStrings(
  needsProject: 'La lista se pasa por obra.',
  loadError: 'No se pudo cargar la asistencia.',
  emptyTitle: 'Sin lista ese día',
  emptyMessage: 'No se pasó lista en la fecha elegida.',
  presentUpper: 'PRESENTES',
  rateUpper: 'ASISTENCIA',
  hoursUpper: 'HORAS',
  ofTotal: '{a} de {b}',
  hourSuffix: 'h',
  unnamedEmployee: 'Empleado',
  statuses: <String, String>{
    'Present': 'Presente',
    'Absent': 'Ausente',
    'Late': 'Tarde',
    'Justified Absence': 'Falta justificada',
  },
);

const PhotosStrings kPhotosEs = PhotosStrings(
  needsProject: 'Las fotos se agrupan por obra.',
  loadError: 'No se pudieron cargar las fotos.',
  emptyTitle: 'Sin fotos',
  emptyMessage: '«{p}» todavía no tiene fotos de avance.',
  deleteTitle: 'Eliminar foto',
  deleteMessage: 'Se borrará del registro y del almacenamiento.',
  deleted: 'Foto eliminada',
);

const ContractorsStrings kContractorsEs = ContractorsStrings(
  tabCompanies: 'Empresas',
  tabContracts: 'Contratos',
  tabPayments: 'Pagos',
  companiesError: 'No se pudieron cargar los contratistas.',
  companiesEmptyTitle: 'Sin contratistas',
  companiesEmptyMessage: 'Aquí aparecerán las empresas subcontratadas.',
  taxId: 'NIT {v}',
  needsProject: 'Los contratos se firman por obra. Crea la primera.',
  contractsError: 'No se pudieron cargar los contratos.',
  contractsEmptyTitle: 'Sin contratos',
  contractsEmptyMessage: '«{p}» no tiene contratos de destajo registrados.',
  untitledContract: 'Contrato',
  paymentsError: 'No se pudieron cargar los pagos.',
  paymentsEmptyTitle: 'Sin pagos',
  paymentsEmptyMessage: 'Todavía no se ha pagado ninguna valuación.',
);

const DayStrings kDayEs = DayStrings(
  previous: 'Día anterior',
  next: 'Día siguiente',
  todayUpper: 'HOY',
  dateUpper: 'FECHA',
);

// ────────────────────────────── português ───────────────────────────────

const ScheduleStrings kSchedulePt = ScheduleStrings(
  needsProject: 'O cronograma é planejado por obra.',
  loadError: 'Não foi possível carregar o cronograma.',
  emptyTitle: 'Sem tarefas',
  emptyMessage: '«{p}» não tem tarefas planejadas.',
  overallProgress: 'Andamento do cronograma',
  doneOfTotal: '{d} de {n} tarefas concluídas',
  doneOfOne: '{d} de 1 tarefa concluída',
  untitled: 'Tarefa',
  late: 'Atrasada',
);

const ProgressStrings kProgressPt = ProgressStrings(
  needsProject: 'O andamento é reportado por obra.',
  loadError: 'Não foi possível carregar o relatório do dia.',
  emptyTitle: 'Sem relatório nesse dia',
  emptyMessage:
      'Não houve registro de andamento na data escolhida. Tente outro dia.',
  reportOfDayUpper: 'RELATÓRIO DO DIA',
  unnamedTask: 'Tarefa',
  executed: 'Executado: {q}',
);

const AttendanceStrings kAttendancePt = AttendanceStrings(
  needsProject: 'A lista é feita por obra.',
  loadError: 'Não foi possível carregar a presença.',
  emptyTitle: 'Sem lista nesse dia',
  emptyMessage: 'Não houve chamada na data escolhida.',
  presentUpper: 'PRESENTES',
  rateUpper: 'PRESENÇA',
  hoursUpper: 'HORAS',
  ofTotal: '{a} de {b}',
  hourSuffix: 'h',
  unnamedEmployee: 'Funcionário',
  statuses: <String, String>{
    'Present': 'Presente',
    'Absent': 'Ausente',
    'Late': 'Atrasado',
    'Justified Absence': 'Falta justificada',
  },
);

const PhotosStrings kPhotosPt = PhotosStrings(
  needsProject: 'As fotos são agrupadas por obra.',
  loadError: 'Não foi possível carregar as fotos.',
  emptyTitle: 'Sem fotos',
  emptyMessage: '«{p}» ainda não tem fotos de andamento.',
  deleteTitle: 'Excluir foto',
  deleteMessage: 'Será apagada do registro e do armazenamento.',
  deleted: 'Foto excluída',
);

const ContractorsStrings kContractorsPt = ContractorsStrings(
  tabCompanies: 'Empresas',
  tabContracts: 'Contratos',
  tabPayments: 'Pagamentos',
  companiesError: 'Não foi possível carregar os empreiteiros.',
  companiesEmptyTitle: 'Sem empreiteiros',
  companiesEmptyMessage: 'Aqui aparecerão as empresas subcontratadas.',
  taxId: 'CNPJ {v}',
  needsProject: 'Os contratos são assinados por obra. Crie a primeira.',
  contractsError: 'Não foi possível carregar os contratos.',
  contractsEmptyTitle: 'Sem contratos',
  contractsEmptyMessage: '«{p}» não tem contratos de empreitada registrados.',
  untitledContract: 'Contrato',
  paymentsError: 'Não foi possível carregar os pagamentos.',
  paymentsEmptyTitle: 'Sem pagamentos',
  paymentsEmptyMessage: 'Ainda não foi paga nenhuma medição.',
);

const DayStrings kDayPt = DayStrings(
  previous: 'Dia anterior',
  next: 'Próximo dia',
  todayUpper: 'HOJE',
  dateUpper: 'DATA',
);

// ─────────────────────────────── english ────────────────────────────────

const ScheduleStrings kScheduleEn = ScheduleStrings(
  needsProject: 'Schedules are planned per site.',
  loadError: 'The schedule could not be loaded.',
  emptyTitle: 'No tasks',
  emptyMessage: '“{p}” has no planned tasks.',
  overallProgress: 'Schedule progress',
  doneOfTotal: '{d} of {n} tasks finished',
  doneOfOne: '{d} of 1 task finished',
  untitled: 'Task',
  late: 'Overdue',
);

const ProgressStrings kProgressEn = ProgressStrings(
  needsProject: 'Progress is reported per site.',
  loadError: 'The daily report could not be loaded.',
  emptyTitle: 'No report that day',
  emptyMessage: 'No progress was logged on the chosen date. Try another day.',
  reportOfDayUpper: 'DAILY REPORT',
  unnamedTask: 'Task',
  executed: 'Completed: {q}',
);

const AttendanceStrings kAttendanceEn = AttendanceStrings(
  needsProject: 'Attendance is taken per site.',
  loadError: 'Attendance could not be loaded.',
  emptyTitle: 'No roll call that day',
  emptyMessage: 'No attendance was taken on the chosen date.',
  presentUpper: 'PRESENT',
  rateUpper: 'ATTENDANCE',
  hoursUpper: 'HOURS',
  ofTotal: '{a} of {b}',
  hourSuffix: 'h',
  unnamedEmployee: 'Employee',
  statuses: <String, String>{
    'Present': 'Present',
    'Absent': 'Absent',
    'Late': 'Late',
    'Justified Absence': 'Excused absence',
  },
);

const PhotosStrings kPhotosEn = PhotosStrings(
  needsProject: 'Photos are grouped by site.',
  loadError: 'Photos could not be loaded.',
  emptyTitle: 'No photos',
  emptyMessage: '“{p}” has no progress photos yet.',
  deleteTitle: 'Delete photo',
  deleteMessage: 'It will be removed from the records and from storage.',
  deleted: 'Photo deleted',
);

const ContractorsStrings kContractorsEn = ContractorsStrings(
  tabCompanies: 'Companies',
  tabContracts: 'Contracts',
  tabPayments: 'Payments',
  companiesError: 'Contractors could not be loaded.',
  companiesEmptyTitle: 'No contractors',
  companiesEmptyMessage: 'Subcontracted companies will show up here.',
  taxId: 'Tax ID {v}',
  needsProject: 'Contracts are signed per site. Create the first one.',
  contractsError: 'Contracts could not be loaded.',
  contractsEmptyTitle: 'No contracts',
  contractsEmptyMessage: '“{p}” has no piecework contracts recorded.',
  untitledContract: 'Contract',
  paymentsError: 'Payments could not be loaded.',
  paymentsEmptyTitle: 'No payments',
  paymentsEmptyMessage: 'No valuation has been paid yet.',
);

const DayStrings kDayEn = DayStrings(
  previous: 'Previous day',
  next: 'Next day',
  todayUpper: 'TODAY',
  dateUpper: 'DATE',
);
