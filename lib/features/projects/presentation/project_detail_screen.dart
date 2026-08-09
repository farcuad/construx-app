import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/admin_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/neon_background.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../clients/application/clients_controller.dart';
import '../../home/presentation/widgets/app_nav_bar.dart';
import '../application/projects_controller.dart';
import '../domain/project.dart';
import '../domain/project_kpis.dart';

/// Detalle de un proyecto con sus KPIs financieros
/// (`GET /dashboard/financial/{project_id}`).
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({required this.projectId, super.key});

  static const String routeName = 'project-detail';

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `select` sobre la lista ya cargada: no se pide el proyecto otra vez.
    final Project? project = ref.watch(
      projectsControllerProvider.select(
        (AsyncValue<List<Project>> value) => value.valueOrNull
            ?.where((Project p) => p.id == projectId)
            .firstOrNull,
      ),
    );

    final ProjectsStrings strings = ref.watch(stringsProvider).projects;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          project?.name ?? strings.fallbackTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/projects'),
        ),
      ),
      // El detalle es una vista más: la barra inferior no desaparece por bajar
      // un nivel.
      bottomNavigationBar: const AppNavBar(currentPath: '/projects'),
      body: NeonBackground(
        child: project == null
            ? EmptyState(
                icon: Icons.search_off_rounded,
                title: strings.notFoundTitle,
                message: strings.notFoundMessage,
              )
            : _DetailBody(project: project),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    final String? clientName = ref.watch(clientNamesProvider)[project.clientId];
    final bool canSeeKpis = user?.can(Perm.dashboardRead) ?? false;
    final AppStrings all = ref.watch(stringsProvider);
    final ProjectsStrings strings = all.projects;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        AppCard(
          glowColor: AppColors.orange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                strings.projectBudgetUpper,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Fmt.money(project.budget),
                style: const TextStyle(
                  color: AppColors.orangeNeon,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.handshake_outlined,
                label: all.common.client,
                value: clientName ?? strings.unassigned,
              ),
              _InfoRow(
                icon: Icons.place_outlined,
                label: all.common.location,
                value: project.location.isEmpty ? '—' : project.location,
              ),
              _InfoRow(
                icon: Icons.play_arrow_rounded,
                label: all.common.start,
                value: Fmt.date(project.startDate),
              ),
              _InfoRow(
                icon: Icons.flag_outlined,
                label: strings.expectedEnd,
                value: Fmt.date(project.endDate),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (canSeeKpis)
          _KpiSection(projectId: project.id)
        else
          AppCard(
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.noDashboardAccess,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _KpiSection extends ConsumerWidget {
  const _KpiSection({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProjectKpis> kpis = ref.watch(
      projectKpisProvider(projectId),
    );
    final AppStrings all = ref.watch(stringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            all.projects.financialSummary,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        switch (kpis) {
          AsyncData<ProjectKpis>(:final ProjectKpis value) => _KpiGrid(
            kpis: value,
          ),
          AsyncError<ProjectKpis>(:final Object error) => AppCard(
            child: Text(
              error is ApiException ? error.message : all.dashboard.kpisError,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          _ => const SizedBox(height: 120, child: LoadingView()),
        },
      ],
    );
  }
}

class _KpiGrid extends ConsumerWidget {
  const _KpiGrid({required this.kpis});

  final ProjectKpis kpis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings all = ref.watch(stringsProvider);
    final DashboardStrings strings = all.dashboard;
    final double? used = kpis.budgetUsedPercent;

    return Column(
      children: <Widget>[
        if (used != null) ...<Widget>[
          AppCard(
            glowColor: kpis.isOverBudget
                ? AppColors.danger
                : AppColors.cyanNeon,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        strings.budgetUsed,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      Fmt.percent(used),
                      style: TextStyle(
                        color: kpis.isOverBudget
                            ? AppColors.danger
                            : AppColors.cyanNeon,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  child: LinearProgressIndicator(
                    value: (used / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      kpis.isOverBudget
                          ? AppColors.danger
                          : AppColors.orangeNeon,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: <Widget>[
            _KpiTile(
              label: strings.expenses,
              value: kpis.totalExpenses,
              color: AppColors.warning,
              icon: Icons.payments_outlined,
            ),
            _KpiTile(
              label: strings.purchases,
              value: kpis.totalPurchased,
              color: AppColors.orange,
              icon: Icons.shopping_cart_outlined,
            ),
            _KpiTile(
              label: strings.invoiced,
              value: kpis.totalInvoiced,
              color: AppColors.cyanNeon,
              icon: Icons.receipt_long_outlined,
            ),
            _KpiTile(
              label: strings.collected,
              value: kpis.totalCollected,
              color: AppColors.success,
              icon: Icons.savings_outlined,
            ),
            _KpiTile(
              label: all.projects.paidToProvidersShort,
              value: kpis.totalPaidToProviders,
              color: AppColors.textSecondary,
              icon: Icons.local_shipping_outlined,
            ),
            _KpiTile(
              label: all.projects.varianceShort,
              value: kpis.financialVariance,
              color: kpis.financialVariance < 0
                  ? AppColors.danger
                  : AppColors.success,
              icon: Icons.query_stats_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Fmt.moneyCompact(value),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 16, color: AppColors.textDisabled),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
