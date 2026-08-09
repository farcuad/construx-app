import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/finance_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import '../application/invoices_providers.dart';
import '../domain/invoice_models.dart';

/// Facturas de la obra seleccionada (`GET /invoices/project/{project_id}`).
class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  static const String routeName = 'invoices';
  static const String routePath = '/invoices';

  @override
  Widget build(BuildContext context, WidgetRef ref) => ModuleScaffold(
    title: 'Facturación',
    currentPath: routePath,
    onRefresh: () => ref.invalidate(projectInvoicesProvider),
    body: ProjectScope(
      emptyMessage: ref.watch(stringsProvider).invoices.needsProject,
      builder: (BuildContext context, Project project) =>
          _InvoicesList(project: project),
    ),
  );
}

class _InvoicesList extends ConsumerWidget {
  const _InvoicesList({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Invoice>> invoices = ref.watch(
      projectInvoicesProvider(project.id),
    );
    final InvoicesStrings strings = ref.watch(stringsProvider).invoices;

    return AsyncSection<List<Invoice>>(
      value: invoices,
      errorMessage: strings.loadError,
      onRetry: () => ref.invalidate(projectInvoicesProvider(project.id)),
      builder: (List<Invoice> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_rounded,
              title: strings.emptyTitle,
              message: strings.emptyFor(project.name),
            )
          : ModuleList(
              itemCount: data.length,
              onRefresh: () async =>
                  ref.invalidate(projectInvoicesProvider(project.id)),
              header: _Summary(invoices: data),
              itemBuilder: (BuildContext context, int index) =>
                  _InvoiceCard(invoice: data[index]),
            ),
    );
  }
}

/// Cuánto se ha emitido y cuánto queda por cobrar.
class _Summary extends ConsumerWidget {
  const _Summary({required this.invoices});

  final List<Invoice> invoices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InvoicesStrings strings = ref.watch(stringsProvider).invoices;
    double issued = 0;
    double pending = 0;
    for (final Invoice invoice in invoices) {
      if (invoice.isCancelled) continue;
      issued += invoice.totalAmount;
      pending += invoice.remainingAmount;
    }

    return AppCard(
      glowColor: AppColors.orange,
      child: Row(
        children: <Widget>[
          Expanded(
            child: LabeledValue(
              label: strings.issuedUpper,
              value: Fmt.money(issued),
              color: AppColors.orangeNeon,
            ),
          ),
          Expanded(
            child: LabeledValue(
              label: strings.pendingCollectionUpper,
              value: Fmt.money(pending),
              color: pending > 0 ? AppColors.warning : AppColors.success,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends ConsumerWidget {
  const _InvoiceCard({required this.invoice});

  final Invoice invoice;

  /// El vencimiento manda sobre el estado: una factura «emitida» pero vencida
  /// se pinta en rojo, que es la información accionable.
  (Color, String) _badge(InvoicesStrings strings) {
    if (invoice.isCancelled) {
      return (AppColors.textDisabled, strings.cancelled);
    }
    if (invoice.isPaid) return (AppColors.success, strings.paidStatus);
    if (invoice.isOverdue) return (AppColors.danger, strings.overdue);
    return (AppColors.warning, invoice.status.isEmpty ? '—' : invoice.status);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    final AppStrings all = ref.watch(stringsProvider);
    final InvoicesStrings strings = all.invoices;
    final bool canCancel =
        (user?.can(Perm.invoicesCancel) ?? false) &&
        !invoice.isCancelled &&
        !invoice.isPaid;
    final (Color color, String label) = _badge(strings);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LeadingIcon(icon: Icons.receipt_long_rounded, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            invoice.invoiceNumber.isEmpty
                                ? strings.noNumber
                                : invoice.invoiceNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(label: label, color: color),
                      ],
                    ),
                    InfoLine(
                      icon: Icons.swap_horiz_rounded,
                      text: invoice.type.label,
                    ),
                    InfoLine(
                      icon: Icons.event_rounded,
                      text: strings.datesOf(
                        Fmt.date(invoice.issueDate),
                        Fmt.date(invoice.dueDate),
                      ),
                      color: invoice.isOverdue ? AppColors.danger : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: LabeledValue(
                  label: all.common.totalUpper,
                  value: Fmt.money(invoice.totalAmount),
                ),
              ),
              Expanded(
                child: LabeledValue(
                  label: strings.pendingUpper,
                  value: Fmt.money(invoice.remainingAmount),
                  color: invoice.remainingAmount > 0
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
              if (canCancel)
                TextButton(
                  onPressed: () => _cancel(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  child: Text(strings.cancel),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final InvoicesStrings strings = ref.read(stringsProvider).invoices;
    final bool confirmed = await confirmDestructive(
      context,
      title: strings.cancelTitle,
      message: strings.cancelBody(invoice.invoiceNumber),
      confirmLabel: strings.cancel,
    );
    if (!confirmed || !context.mounted) return;

    final bool ok = await runWithFeedback(
      context,
      action: () => ref.read(invoicesRepositoryProvider).cancel(invoice.id),
      successMessage: strings.cancelDone,
    );
    if (ok) ref.invalidate(projectInvoicesProvider(invoice.projectId));
  }
}
