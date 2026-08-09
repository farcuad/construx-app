import 'package:flutter/foundation.dart';

import 'common_strings.dart';

/// Textos de los módulos que mueven dinero: presupuestos, gastos, órdenes de
/// compra, proveedores y facturación.
///
/// Las plantillas llevan huecos entre llaves (`{p}` = obra, `{n}` = cifra) que
/// se rellenan con los métodos de cada clase, para que las pantallas no tengan
/// que saber cómo está escrita la frase.
@immutable
class BudgetsStrings {
  const BudgetsStrings({
    required this.needsProject,
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.countOne,
    required this.countMany,
    required this.untitled,
    required this.itemsOne,
    required this.itemsMany,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.deleted,
  });

  final String needsProject;
  final String loadError;
  final String emptyTitle;
  final String emptyMessage;
  final String countOne;
  final String countMany;
  final String untitled;
  final String itemsOne;
  final String itemsMany;
  final String deleteTitle;
  final String deleteMessage;
  final String deleted;

  String emptyFor(String project) =>
      fill(emptyMessage, <String, String>{'p': project});
  String count(int n) => plural(n, countOne, countMany);
  String items(int n) => plural(n, itemsOne, itemsMany);
  String deleteBody(String title) =>
      fill(deleteMessage, <String, String>{'t': title});
}

@immutable
class ExpensesStrings {
  const ExpensesStrings({
    required this.needsProject,
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.countOne,
    required this.countMany,
    required this.untitled,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.deleted,
    required this.formNew,
    required this.formEdit,
    required this.concept,
    required this.conceptRequired,
    required this.expenseDate,
    required this.submit,
    required this.created,
    required this.updated,
  });

  final String needsProject;
  final String loadError;
  final String emptyTitle;
  final String emptyMessage;
  final String countOne;
  final String countMany;
  final String untitled;
  final String deleteTitle;
  final String deleteMessage;
  final String deleted;
  final String formNew;
  final String formEdit;
  final String concept;
  final String conceptRequired;
  final String expenseDate;
  final String submit;
  final String created;
  final String updated;

  String emptyFor(String project) =>
      fill(emptyMessage, <String, String>{'p': project});
  String count(int n) => plural(n, countOne, countMany);
  String deleteBody(String title, String amount) =>
      fill(deleteMessage, <String, String>{'t': title, 'a': amount});
}

@immutable
class PurchasesStrings {
  const PurchasesStrings({
    required this.needsProject,
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.noSupplier,
    required this.delivery,
    required this.linesOne,
    required this.linesMany,
    required this.approve,
    required this.approved,
  });

  final String needsProject;
  final String loadError;
  final String emptyTitle;
  final String emptyMessage;
  final String noSupplier;

  /// Con `{d}` como hueco para la fecha.
  final String delivery;

  final String linesOne;
  final String linesMany;
  final String approve;
  final String approved;

  String emptyFor(String project) =>
      fill(emptyMessage, <String, String>{'p': project});
  String deliveryOn(String date) => fill(delivery, <String, String>{'d': date});
  String lines(int n) => plural(n, linesOne, linesMany);
}

@immutable
class SuppliersStrings {
  const SuppliersStrings({
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.taxId,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.deleted,
  });

  final String loadError;
  final String emptyTitle;
  final String emptyMessage;

  /// Identificador fiscal. Con `{v}` como hueco para el número.
  final String taxId;

  final String deleteTitle;
  final String deleteMessage;
  final String deleted;

  String taxIdOf(String value) => fill(taxId, <String, String>{'v': value});
  String deleteBody(String name) =>
      fill(deleteMessage, <String, String>{'n': name});
}

@immutable
class InvoicesStrings {
  const InvoicesStrings({
    required this.needsProject,
    required this.loadError,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.issuedUpper,
    required this.pendingCollectionUpper,
    required this.pendingUpper,
    required this.noNumber,
    required this.cancelled,
    required this.paidStatus,
    required this.overdue,
    required this.dates,
    required this.cancel,
    required this.cancelTitle,
    required this.cancelMessage,
    required this.cancelDone,
  });

  final String needsProject;
  final String loadError;
  final String emptyTitle;
  final String emptyMessage;
  final String issuedUpper;
  final String pendingCollectionUpper;
  final String pendingUpper;
  final String noNumber;
  final String cancelled;
  final String paidStatus;
  final String overdue;

  /// Emisión y vencimiento: `{i}` y `{d}`.
  final String dates;

  final String cancel;
  final String cancelTitle;
  final String cancelMessage;
  final String cancelDone;

  String emptyFor(String project) =>
      fill(emptyMessage, <String, String>{'p': project});
  String datesOf(String issued, String due) =>
      fill(dates, <String, String>{'i': issued, 'd': due});
  String cancelBody(String number) =>
      fill(cancelMessage, <String, String>{'n': number});
}

// ─────────────────────────────── español ────────────────────────────────

const BudgetsStrings kBudgetsEs = BudgetsStrings(
  needsProject: 'Los presupuestos se hacen por obra. Crea la primera.',
  loadError: 'No se pudieron cargar los presupuestos.',
  emptyTitle: 'Sin presupuestos',
  emptyMessage: '«{p}» aún no tiene presupuestos cargados.',
  countOne: '1 PRESUPUESTO',
  countMany: '{n} PRESUPUESTOS',
  untitled: 'Presupuesto',
  itemsOne: '1 partida',
  itemsMany: '{n} partidas',
  deleteTitle: 'Eliminar presupuesto',
  deleteMessage: 'Se eliminará «{t}» y todas sus partidas.',
  deleted: 'Presupuesto eliminado',
);

const ExpensesStrings kExpensesEs = ExpensesStrings(
  needsProject: 'Los gastos se imputan a una obra. Crea la primera.',
  loadError: 'No se pudieron cargar los gastos.',
  emptyTitle: 'Sin gastos',
  emptyMessage: '«{p}» no tiene gastos registrados todavía.',
  countOne: '1 GASTO',
  countMany: '{n} GASTOS',
  untitled: 'Gasto',
  deleteTitle: 'Eliminar gasto',
  deleteMessage: 'Se eliminará «{t}» por {a}.',
  deleted: 'Gasto eliminado',
  formNew: 'Nuevo gasto',
  formEdit: 'Editar gasto',
  concept: 'Concepto',
  conceptRequired: 'Ingresa el concepto',
  expenseDate: 'Fecha del gasto',
  submit: 'Registrar gasto',
  created: 'Gasto registrado',
  updated: 'Gasto actualizado',
);

const PurchasesStrings kPurchasesEs = PurchasesStrings(
  needsProject: 'Las órdenes de compra se emiten para una obra.',
  loadError: 'No se pudieron cargar las órdenes de compra.',
  emptyTitle: 'Sin órdenes de compra',
  emptyMessage: '«{p}» no tiene compras registradas.',
  noSupplier: 'Proveedor sin asignar',
  delivery: 'Entrega {d}',
  linesOne: '1 línea',
  linesMany: '{n} líneas',
  approve: 'Aprobar',
  approved: 'Orden aprobada',
);

const SuppliersStrings kSuppliersEs = SuppliersStrings(
  loadError: 'No se pudieron cargar los proveedores.',
  emptyTitle: 'Sin proveedores',
  emptyMessage:
      'Cuando tu empresa dé de alta proveedores, aparecerán aquí '
      'para asociarlos a las órdenes de compra.',
  taxId: 'NIT {v}',
  deleteTitle: 'Eliminar proveedor',
  deleteMessage: 'Se eliminará «{n}».',
  deleted: 'Proveedor eliminado',
);

const InvoicesStrings kInvoicesEs = InvoicesStrings(
  needsProject: 'Las facturas se emiten contra una obra.',
  loadError: 'No se pudieron cargar las facturas.',
  emptyTitle: 'Sin facturas',
  emptyMessage: '«{p}» no tiene facturas registradas.',
  issuedUpper: 'EMITIDO',
  pendingCollectionUpper: 'PENDIENTE DE COBRO',
  pendingUpper: 'PENDIENTE',
  noNumber: 'Sin número',
  cancelled: 'Anulada',
  paidStatus: 'Pagada',
  overdue: 'Vencida',
  dates: 'Emitida {i} · vence {d}',
  cancel: 'Anular',
  cancelTitle: 'Anular factura',
  cancelMessage:
      'Se anulará la factura {n}. Esta acción queda registrada en la '
      'auditoría.',
  cancelDone: 'Factura anulada',
);

// ────────────────────────────── português ───────────────────────────────

const BudgetsStrings kBudgetsPt = BudgetsStrings(
  needsProject: 'Os orçamentos são feitos por obra. Crie a primeira.',
  loadError: 'Não foi possível carregar os orçamentos.',
  emptyTitle: 'Sem orçamentos',
  emptyMessage: '«{p}» ainda não tem orçamentos carregados.',
  countOne: '1 ORÇAMENTO',
  countMany: '{n} ORÇAMENTOS',
  untitled: 'Orçamento',
  itemsOne: '1 item',
  itemsMany: '{n} itens',
  deleteTitle: 'Excluir orçamento',
  deleteMessage: '«{t}» e todos os seus itens serão excluídos.',
  deleted: 'Orçamento excluído',
);

const ExpensesStrings kExpensesPt = ExpensesStrings(
  needsProject: 'As despesas são lançadas em uma obra. Crie a primeira.',
  loadError: 'Não foi possível carregar as despesas.',
  emptyTitle: 'Sem despesas',
  emptyMessage: '«{p}» ainda não tem despesas registradas.',
  countOne: '1 DESPESA',
  countMany: '{n} DESPESAS',
  untitled: 'Despesa',
  deleteTitle: 'Excluir despesa',
  deleteMessage: '«{t}» de {a} será excluída.',
  deleted: 'Despesa excluída',
  formNew: 'Nova despesa',
  formEdit: 'Editar despesa',
  concept: 'Descrição do gasto',
  conceptRequired: 'Informe o gasto',
  expenseDate: 'Data da despesa',
  submit: 'Registrar despesa',
  created: 'Despesa registrada',
  updated: 'Despesa atualizada',
);

const PurchasesStrings kPurchasesPt = PurchasesStrings(
  needsProject: 'As ordens de compra são emitidas para uma obra.',
  loadError: 'Não foi possível carregar as ordens de compra.',
  emptyTitle: 'Sem ordens de compra',
  emptyMessage: '«{p}» não tem compras registradas.',
  noSupplier: 'Fornecedor não atribuído',
  delivery: 'Entrega {d}',
  linesOne: '1 linha',
  linesMany: '{n} linhas',
  approve: 'Aprovar',
  approved: 'Ordem aprovada',
);

const SuppliersStrings kSuppliersPt = SuppliersStrings(
  loadError: 'Não foi possível carregar os fornecedores.',
  emptyTitle: 'Sem fornecedores',
  emptyMessage:
      'Quando a sua empresa cadastrar fornecedores, eles aparecerão aqui '
      'para serem vinculados às ordens de compra.',
  taxId: 'CNPJ {v}',
  deleteTitle: 'Excluir fornecedor',
  deleteMessage: '«{n}» será excluído.',
  deleted: 'Fornecedor excluído',
);

const InvoicesStrings kInvoicesPt = InvoicesStrings(
  needsProject: 'As faturas são emitidas contra uma obra.',
  loadError: 'Não foi possível carregar as faturas.',
  emptyTitle: 'Sem faturas',
  emptyMessage: '«{p}» não tem faturas registradas.',
  issuedUpper: 'EMITIDO',
  pendingCollectionUpper: 'A RECEBER',
  pendingUpper: 'PENDENTE',
  noNumber: 'Sem número',
  cancelled: 'Cancelada',
  paidStatus: 'Paga',
  overdue: 'Vencida',
  dates: 'Emitida {i} · vence {d}',
  cancel: 'Cancelar fatura',
  cancelTitle: 'Cancelar fatura',
  cancelMessage:
      'A fatura {n} será cancelada. Esta ação fica registrada na auditoria.',
  cancelDone: 'Fatura cancelada',
);

// ─────────────────────────────── english ────────────────────────────────

const BudgetsStrings kBudgetsEn = BudgetsStrings(
  needsProject: 'Budgets are drawn up per site. Create the first one.',
  loadError: 'Budgets could not be loaded.',
  emptyTitle: 'No budgets',
  emptyMessage: '“{p}” has no budgets loaded yet.',
  countOne: '1 BUDGET',
  countMany: '{n} BUDGETS',
  untitled: 'Budget',
  itemsOne: '1 line item',
  itemsMany: '{n} line items',
  deleteTitle: 'Delete budget',
  deleteMessage: '“{t}” and all its line items will be deleted.',
  deleted: 'Budget deleted',
);

const ExpensesStrings kExpensesEn = ExpensesStrings(
  needsProject: 'Expenses are charged to a site. Create the first one.',
  loadError: 'Expenses could not be loaded.',
  emptyTitle: 'No expenses',
  emptyMessage: '“{p}” has no expenses recorded yet.',
  countOne: '1 EXPENSE',
  countMany: '{n} EXPENSES',
  untitled: 'Expense',
  deleteTitle: 'Delete expense',
  deleteMessage: '“{t}” for {a} will be deleted.',
  deleted: 'Expense deleted',
  formNew: 'New expense',
  formEdit: 'Edit expense',
  concept: 'What it was for',
  conceptRequired: 'Enter what it was for',
  expenseDate: 'Expense date',
  submit: 'Record expense',
  created: 'Expense recorded',
  updated: 'Expense updated',
);

const PurchasesStrings kPurchasesEn = PurchasesStrings(
  needsProject: 'Purchase orders are issued for a site.',
  loadError: 'Purchase orders could not be loaded.',
  emptyTitle: 'No purchase orders',
  emptyMessage: '“{p}” has no purchases recorded.',
  noSupplier: 'No supplier assigned',
  delivery: 'Delivery {d}',
  linesOne: '1 line',
  linesMany: '{n} lines',
  approve: 'Approve',
  approved: 'Order approved',
);

const SuppliersStrings kSuppliersEn = SuppliersStrings(
  loadError: 'Suppliers could not be loaded.',
  emptyTitle: 'No suppliers',
  emptyMessage:
      'Once your company registers suppliers, they will show up here to be '
      'linked to purchase orders.',
  taxId: 'Tax ID {v}',
  deleteTitle: 'Delete supplier',
  deleteMessage: '“{n}” will be deleted.',
  deleted: 'Supplier deleted',
);

const InvoicesStrings kInvoicesEn = InvoicesStrings(
  needsProject: 'Invoices are issued against a site.',
  loadError: 'Invoices could not be loaded.',
  emptyTitle: 'No invoices',
  emptyMessage: '“{p}” has no invoices recorded.',
  issuedUpper: 'ISSUED',
  pendingCollectionUpper: 'AWAITING PAYMENT',
  pendingUpper: 'OUTSTANDING',
  noNumber: 'No number',
  cancelled: 'Voided',
  paidStatus: 'Paid',
  overdue: 'Overdue',
  dates: 'Issued {i} · due {d}',
  cancel: 'Void',
  cancelTitle: 'Void invoice',
  cancelMessage:
      'Invoice {n} will be voided. This action is recorded in the audit log.',
  cancelDone: 'Invoice voided',
);
