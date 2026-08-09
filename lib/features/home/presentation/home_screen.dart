import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/admin_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/neon_background.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../notifications/presentation/widgets/notifications_bell.dart';
import '../../projects/application/project_scope.dart';
import '../../projects/application/projects_controller.dart';
import '../../projects/domain/project.dart';
import '../../projects/domain/project_kpis.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import 'widgets/app_drawer.dart';
import 'widgets/app_nav_bar.dart';
import 'widgets/kpi_card.dart';

/// Panel principal: indicadores financieros del proyecto seleccionado
/// (`GET /dashboard/financial/{project_id}`).
///
/// Los módulos del ERP ya no viven aquí, sino en el menú lateral
/// ([AppDrawer]); esta pantalla es el tablero de mando.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String routeName = 'home';
  static const String routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: LoadingView());

    return Scaffold(
      drawer: const AppDrawer(currentPath: routePath),
      bottomNavigationBar: const AppNavBar(currentPath: routePath),
      body: NeonBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.orangeNeon,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await ref.read(projectsControllerProvider.notifier).refresh();
              // Al invalidar la familia entera, el proyecto que se esté viendo
              // vuelve a pedir sus KPIs sin tener que saber cuál es.
              ref.invalidate(projectKpisProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(child: _Header(user: user)),
                ..._buildDashboard(context, ref, user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cuerpo del panel según haya proyectos, permisos y datos.
  List<Widget> _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    AuthUser user,
  ) {
    final AsyncValue<List<Project>> projects = ref.watch(
      projectsControllerProvider,
    );

    final DashboardStrings strings = ref.watch(stringsProvider).dashboard;

    return switch (projects) {
      AsyncError<List<Project>>(:final Object error) => <Widget>[
        _fill(
          ErrorView(
            message: error is ApiException
                ? error.message
                : strings.projectsError,
            onRetry: () =>
                ref.read(projectsControllerProvider.notifier).refresh(),
          ),
        ),
      ],
      AsyncData<List<Project>>() => _buildForProject(context, ref, user),
      _ => const <Widget>[_Fill(child: LoadingView())],
    };
  }

  List<Widget> _buildForProject(
    BuildContext context,
    WidgetRef ref,
    AuthUser user,
  ) {
    final Project? project = ref.watch(activeProjectProvider);
    final AppStrings all = ref.watch(stringsProvider);
    final DashboardStrings strings = all.dashboard;

    if (project == null) {
      return <Widget>[
        _fill(
          EmptyState(
            icon: Icons.apartment_rounded,
            title: all.projectScope.emptyTitle,
            message: strings.noProjectsMessage,
            action: user.can(Perm.projectsCreate)
                ? FilledButton.icon(
                    onPressed: () => context.go('/projects'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(all.projectScope.goToProjects),
                  )
                : null,
          ),
        ),
      ];
    }

    return <Widget>[
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 18),
        sliver: SliverToBoxAdapter(child: ProjectSelector()),
      ),
      if (!user.can(Perm.dashboardRead))
        _fill(
          EmptyState(
            icon: Icons.lock_outline_rounded,
            title: strings.noAccessTitle,
            message: strings.noAccessMessage,
          ),
        )
      else
        ..._buildKpis(ref, project),
    ];
  }

  List<Widget> _buildKpis(WidgetRef ref, Project project) {
    final AsyncValue<ProjectKpis> kpis = ref.watch(
      projectKpisProvider(project.id),
    );
    final DashboardStrings strings = ref.watch(stringsProvider).dashboard;

    return switch (kpis) {
      AsyncData<ProjectKpis>(:final ProjectKpis value) => <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          sliver: SliverToBoxAdapter(child: _BudgetSummary(kpis: value)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 210,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              // Alto fijo en vez de proporción: la tarjeta no cambia de altura
              // con el ancho, y así la rejilla no reflow­ea al girar el móvil.
              mainAxisExtent: 130,
            ),
            itemCount: _kpiTiles(strings, value).length,
            itemBuilder: (BuildContext context, int index) =>
                _kpiTiles(strings, value)[index],
          ),
        ),
      ],
      AsyncError<ProjectKpis>(:final Object error) => <Widget>[
        _fill(
          ErrorView(
            message: error is ApiException ? error.message : strings.kpisError,
            onRetry: () => ref.invalidate(projectKpisProvider(project.id)),
          ),
        ),
      ],
      _ => const <Widget>[_Fill(child: LoadingView())],
    };
  }

  /// Las siete cifras que devuelve `/dashboard/financial/{project_id}`.
  List<Widget> _kpiTiles(DashboardStrings s, ProjectKpis k) {
    final double pendingToCollect = k.totalInvoiced - k.totalCollected;
    return <Widget>[
      KpiCard(
        label: s.totalBudget,
        amount: k.totalBudget,
        icon: Icons.account_balance_wallet_rounded,
        accent: AppColors.orangeNeon,
      ),
      KpiCard(
        label: s.expenses,
        amount: k.totalExpenses,
        icon: Icons.payments_rounded,
        accent: AppColors.warning,
      ),
      KpiCard(
        label: s.purchases,
        amount: k.totalPurchased,
        icon: Icons.shopping_cart_checkout_rounded,
        accent: AppColors.cyanNeon,
      ),
      KpiCard(
        label: s.invoiced,
        amount: k.totalInvoiced,
        icon: Icons.receipt_long_rounded,
        accent: AppColors.orange,
      ),
      KpiCard(
        label: s.collected,
        amount: k.totalCollected,
        icon: Icons.call_received_rounded,
        accent: AppColors.success,
        footnote: pendingToCollect > 0
            ? s.pendingOf(Fmt.moneyCompact(pendingToCollect))
            : s.allCollected,
      ),
      KpiCard(
        label: s.paidToProviders,
        amount: k.totalPaidToProviders,
        icon: Icons.call_made_rounded,
        accent: AppColors.textSecondary,
      ),
      KpiCard(
        label: s.variance,
        amount: k.financialVariance,
        icon: Icons.balance_rounded,
        accent: k.financialVariance >= 0 ? AppColors.success : AppColors.danger,
        footnote: k.financialVariance >= 0 ? s.inFavour : s.against,
      ),
    ];
  }

  static Widget _fill(Widget child) => _Fill(child: child);
}

/// Ocupa el resto de la pantalla para centrar estados vacíos y de error sin
/// perder el gesto de «tirar para refrescar».
class _Fill extends StatelessWidget {
  const _Fill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SliverFillRemaining(hasScrollBody: false, child: child);
}

/// Barra de consumo del presupuesto: gastos + compras frente al presupuesto.
class _BudgetSummary extends ConsumerWidget {
  const _BudgetSummary({required this.kpis});

  final ProjectKpis kpis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings all = ref.watch(stringsProvider);
    final DashboardStrings strings = all.dashboard;
    final double? percent = kpis.budgetUsedPercent;
    final double committed = kpis.totalExpenses + kpis.totalPurchased;
    final Color accent = kpis.isOverBudget
        ? AppColors.danger
        : (percent ?? 0) > 80
        ? AppColors.warning
        : AppColors.orange;

    return AppCard(
      glowColor: accent,
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusChip(
                label: percent == null
                    ? strings.noBudget
                    : Fmt.percent(percent),
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(
              value: percent == null ? 0 : (percent / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.surfaceHigh,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _Figure(
                  label: strings.committed,
                  value: Fmt.money(committed),
                  color: accent,
                ),
              ),
              Expanded(
                child: _Figure(
                  label: all.common.budget,
                  value: Fmt.money(kpis.totalBudget),
                  color: AppColors.textPrimary,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (kpis.isOverBudget) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 15,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    strings.overBudgetBy(
                      Fmt.money(committed - kpis.totalBudget),
                    ),
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        label,
        style: const TextStyle(color: AppColors.textDisabled, fontSize: 10.5),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

/// Cabecera del panel: quién ha iniciado sesión, sin más adornos.
///
/// Muestra nombre y correo —lo que identifica a la persona— en lugar de un
/// saludo y unas iniciales, que ocupaban sitio sin decir nada.
///
/// El botón de salir se fue a Ajustes, que está a un toque en la barra
/// inferior: aquí solo queda la campana, que sí se consulta a diario.
class _Header extends ConsumerWidget {
  const _Header({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(stringsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 18),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: strings.openMenu,
            icon: const Icon(Icons.menu_rounded),
            color: AppColors.textPrimary,
            onPressed: Scaffold.of(context).openDrawer,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  user.name.isEmpty ? strings.unknownName : user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const NotificationsBell(),
        ],
      ),
    );
  }
}
