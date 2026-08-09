import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/site_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import '../application/contractors_providers.dart';
import '../domain/contractor_models.dart';

/// Contratistas, sus contratos por obra y los pagos hechos.
class ContractorsScreen extends ConsumerWidget {
  const ContractorsScreen({super.key});

  static const String routeName = 'contractors';
  static const String routePath = '/contractors';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContractorsStrings strings = ref.watch(stringsProvider).contractors;

    return DefaultTabController(
      length: 3,
      child: ModuleScaffold(
        title: 'Contratistas',
        currentPath: routePath,
        onRefresh: () {
          ref.invalidate(contractorsProvider);
          ref.invalidate(projectContractorContractsProvider);
          ref.invalidate(contractorPaymentsProvider);
        },
        bottom: TabBar(
          tabs: <Widget>[
            Tab(text: strings.tabCompanies),
            Tab(text: strings.tabContracts),
            Tab(text: strings.tabPayments),
          ],
        ),
        body: const TabBarView(
          children: <Widget>[_CompaniesTab(), _ContractsTab(), _PaymentsTab()],
        ),
      ),
    );
  }
}

class _CompaniesTab extends ConsumerWidget {
  const _CompaniesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Contractor>> contractors = ref.watch(
      contractorsProvider,
    );
    final AppStrings all = ref.watch(stringsProvider);
    final ContractorsStrings strings = all.contractors;

    return AsyncSection<List<Contractor>>(
      value: contractors,
      errorMessage: strings.companiesError,
      onRetry: () => ref.invalidate(contractorsProvider),
      builder: (List<Contractor> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.groups_rounded,
              title: strings.companiesEmptyTitle,
              message: strings.companiesEmptyMessage,
            )
          : ModuleList(
              itemCount: data.length,
              onRefresh: () async => ref.invalidate(contractorsProvider),
              itemBuilder: (BuildContext context, int index) {
                final Contractor c = data[index];
                return AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LeadingIcon(
                        icon: Icons.groups_rounded,
                        color: c.isActive
                            ? AppColors.orange
                            : AppColors.textDisabled,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    c.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (!c.isActive)
                                  StatusChip(
                                    label: all.common.inactive,
                                    color: AppColors.textDisabled,
                                  ),
                              ],
                            ),
                            if (c.nit.isNotEmpty)
                              InfoLine(
                                icon: Icons.badge_outlined,
                                text: strings.taxIdOf(c.nit),
                              ),
                            if (c.representative.isNotEmpty)
                              InfoLine(
                                icon: Icons.person_outline_rounded,
                                text: c.representative,
                              ),
                            if (c.phone.isNotEmpty)
                              InfoLine(
                                icon: Icons.phone_outlined,
                                text: c.phone,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ContractsTab extends ConsumerWidget {
  const _ContractsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ProjectScope(
    emptyMessage: ref.watch(stringsProvider).contractors.needsProject,
    builder: (BuildContext context, Project project) {
      final AsyncValue<List<ContractorContract>> contracts = ref.watch(
        projectContractorContractsProvider(project.id),
      );
      final ContractorsStrings strings = ref.watch(stringsProvider).contractors;

      return AsyncSection<List<ContractorContract>>(
        value: contracts,
        errorMessage: strings.contractsError,
        onRetry: () =>
            ref.invalidate(projectContractorContractsProvider(project.id)),
        builder: (List<ContractorContract> data) => data.isEmpty
            ? EmptyState(
                icon: Icons.assignment_outlined,
                title: strings.contractsEmptyTitle,
                message: strings.contractsEmptyFor(project.name),
              )
            : ModuleList(
                itemCount: data.length,
                onRefresh: () async => ref.invalidate(
                  projectContractorContractsProvider(project.id),
                ),
                itemBuilder: (BuildContext context, int index) =>
                    _ContractCard(contract: data[index]),
              ),
      );
    },
  );
}

class _ContractCard extends ConsumerWidget {
  const _ContractCard({required this.contract});

  final ContractorContract contract;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(stringsProvider);
    final Color statusColor = switch (contract.status) {
      ContractorContractStatus.active => AppColors.success,
      ContractorContractStatus.finished => AppColors.textSecondary,
      ContractorContractStatus.cancelled => AppColors.danger,
      _ => AppColors.textSecondary,
    };
    final double paid = contract.totalAmount - contract.balance;
    final double percent = contract.totalAmount <= 0
        ? 0
        : paid / contract.totalAmount * 100;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  contract.title.isEmpty
                      ? strings.contractors.untitledContract
                      : contract.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: contract.status.isEmpty ? '—' : contract.status,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(percent: percent, color: statusColor),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: LabeledValue(
                  label: strings.common.paid,
                  value: Fmt.money(paid),
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: LabeledValue(
                  label: strings.common.balance,
                  value: Fmt.money(contract.balance),
                  color: contract.balance > 0
                      ? AppColors.warning
                      : AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: LabeledValue(
                  label: strings.common.total,
                  value: Fmt.money(contract.totalAmount),
                  alignEnd: true,
                ),
              ),
            ],
          ),
          InfoLine(
            icon: Icons.event_rounded,
            text:
                '${Fmt.date(contract.startDate)} → '
                '${Fmt.date(contract.endDate)}',
            top: 10,
          ),
        ],
      ),
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ContractorPayment>> payments = ref.watch(
      contractorPaymentsProvider,
    );

    final ContractorsStrings strings = ref.watch(stringsProvider).contractors;

    return AsyncSection<List<ContractorPayment>>(
      value: payments,
      errorMessage: strings.paymentsError,
      onRetry: () => ref.invalidate(contractorPaymentsProvider),
      builder: (List<ContractorPayment> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.payments_outlined,
              title: strings.paymentsEmptyTitle,
              message: strings.paymentsEmptyMessage,
            )
          : ModuleList(
              itemCount: data.length,
              onRefresh: () async => ref.invalidate(contractorPaymentsProvider),
              itemBuilder: (BuildContext context, int index) {
                final ContractorPayment p = data[index];
                return AppCard(
                  child: Row(
                    children: <Widget>[
                      const LeadingIcon(
                        icon: Icons.receipt_rounded,
                        color: AppColors.success,
                        size: 38,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              Fmt.money(p.amount),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            InfoLine(
                              icon: Icons.event_rounded,
                              text: Fmt.date(p.paymentDate),
                            ),
                            if (p.referenceNumber.isNotEmpty)
                              InfoLine(
                                icon: Icons.tag_rounded,
                                text: p.referenceNumber,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
