import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
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
import '../../projects/domain/project_dashboard_model.dart';
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
    final AsyncValue<ProjectDashboardModel> kpis = ref.watch(
      projectKpisProvider(project.id),
    );
    final DashboardStrings strings = ref.watch(stringsProvider).dashboard;

    return switch (kpis) {
      AsyncData<ProjectDashboardModel>(:final ProjectDashboardModel value) =>
        <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            sliver: SliverToBoxAdapter(child: _BudgetSummary(data: value)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // Alto fijo en vez de proporción: la tarjeta no cambia de
                // altura con el ancho, y así la rejilla no reflowa al girar el
                // móvil. Dos columnas en teléfono, cuatro en tablet.
                mainAxisExtent: 132,
              ),
              itemCount: 4,
              itemBuilder: (BuildContext context, int index) =>
                  _kpiTiles(strings, value)[index],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            sliver: SliverToBoxAdapter(child: _TrendChart(data: value)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverToBoxAdapter(child: _CategoryPieChart(data: value)),
          ),
        ],
      AsyncError<ProjectDashboardModel>(:final Object error) => <Widget>[
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

  /// Las cuatro tarjetas clave del panel financiero.
  List<Widget> _kpiTiles(DashboardStrings s, ProjectDashboardModel k) {
    final double pendingToCollect = k.totalInvoiced - k.totalCollected;
    return <Widget>[
      KpiCard(
        label: s.totalBudget,
        amount: k.totalBudget,
        icon: Icons.account_balance_wallet_rounded,
        accent: AppColors.emerald,
      ),
      KpiCard(
        label: s.totalSpent,
        amount: k.totalSpent,
        icon: Icons.trending_down_rounded,
        accent: AppColors.rose,
      ),
      KpiCard(
        label: s.collectedVsInvoiced,
        amount: k.totalCollected,
        icon: Icons.arrow_upward_rounded,
        accent: AppColors.indigo,
        footnote: pendingToCollect > 0
            ? s.pendingOf(Fmt.moneyCompact(pendingToCollect))
            : s.allCollected,
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

/// Cabecera de una tarjeta de sección del panel.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
  );
}

/// Miniestado para secciones del panel (tendencia, categorías) sin datos.
class _EmptyMini extends StatelessWidget {
  const _EmptyMini({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 42),
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
    ),
  );
}

/// Barra de consumo del presupuesto: gastos + compras frente al presupuesto.
class _BudgetSummary extends ConsumerWidget {
  const _BudgetSummary({required this.data});

  final ProjectDashboardModel data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings all = ref.watch(stringsProvider);
    final DashboardStrings strings = all.dashboard;
    final double? percent = data.budgetUsedPercent;
    final double committed = data.totalSpent;
    final Color accent = data.isOverBudget
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
                  value: Fmt.money(data.totalBudget),
                  color: AppColors.textPrimary,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (data.isOverBudget) ...<Widget>[
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
                      Fmt.money(committed - data.totalBudget),
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

/// Serie corta de la leyenda de un gráfico: mancha de color + etiqueta.
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(3)),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

/// Gráfica de tendencia mensual: facturado, cobrado y gastos.
///
/// Tres curvas suaves con área sombreada y tootips en dólares al tocar un mes.
class _TrendChart extends ConsumerWidget {
  const _TrendChart({required this.data});

  final ProjectDashboardModel data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DashboardStrings strings = ref.watch(stringsProvider).dashboard;
    final List<MonthlyTrend> trends = data.monthlyTrends;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitle(text: strings.trendTitle),
          const SizedBox(height: 16),
          if (trends.isEmpty)
            _EmptyMini(message: strings.noTrendData)
          else ...<Widget>[
            SizedBox(
              height: 232,
              width: double.infinity,
              child: LineChart(_lineData(strings, trends)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: <Widget>[
                _LegendItem(color: AppColors.indigo, label: strings.invoiced),
                _LegendItem(
                  color: AppColors.emerald,
                  label: strings.collected,
                ),
                _LegendItem(color: AppColors.rose, label: strings.expenses),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static LineChartData _lineData(DashboardStrings s, List<MonthlyTrend> trends) {
    final List<(String, Color, double Function(MonthlyTrend))> series =
        <(String, Color, double Function(MonthlyTrend))>[
      (s.invoiced, AppColors.indigo, (MonthlyTrend t) => t.invoiced),
      (s.collected, AppColors.emerald, (MonthlyTrend t) => t.collected),
      (s.expenses, AppColors.rose, (MonthlyTrend t) => t.expenses),
    ];

    List<FlSpot> spots(double Function(MonthlyTrend) pick) =>
        <FlSpot>[
          for (int i = 0; i < trends.length; i++)
            FlSpot(i.toDouble(), pick(trends[i])),
        ];

    double rawMax = 0;
    for (final MonthlyTrend trend in trends) {
      rawMax = math.max(
        rawMax,
        math.max(trend.invoiced, math.max(trend.collected, trend.expenses)),
      );
    }

    final double interval = _niceInterval(rawMax);
    final double maxY = interval * math.max(1, (rawMax / interval).ceil());

    return LineChartData(
      minX: 0,
      maxX: math.max(0, trends.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (double value) => FlLine(
          color: AppColors.border.withValues(alpha: 0.55),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            getTitlesWidget: (double value, TitleMeta meta) =>
                _compactLeftLabel(value, meta),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              final int index = value.toInt();
              if (index < 0 || index >= trends.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  trends[index].month,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipBorderRadius: const BorderRadius.all(Radius.circular(10)),
          tooltipBorder: const BorderSide(color: AppColors.border),
          getTooltipColor: (LineBarSpot spot) => AppColors.surfaceHigh,
          getTooltipItems: (List<LineBarSpot> touchedSpots) =>
              <LineTooltipItem?>[
                for (final LineBarSpot spot in touchedSpots)
                  LineTooltipItem(
                    '${series[spot.barIndex].$1}: '
                    '${Fmt.money(spot.y)}',
                    TextStyle(
                      color: series[spot.barIndex].$2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
        ),
      ),
      lineBarsData: <LineChartBarData>[
        for (final (String _, Color color, double Function(MonthlyTrend) pick)
            in series)
          LineChartBarData(
            spots: spots(pick),
            color: color,
            isCurved: true,
            curveSmoothness: 0.32,
            barWidth: 2.2,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.02),
                ],
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter:
                  (FlSpot spot, double xPercentage, LineChartBarData bar,
                      int index) => FlDotCirclePainter(
                        radius: 2.6,
                        color: AppColors.surface,
                        strokeWidth: 2,
                        strokeColor: color,
                      ),
            ),
          ),
      ],
    );
  }

  /// Etiqueta compacta del eje Y (`$2,5 M`), alineada a la derecha del gráfico.
  static Widget _compactLeftLabel(double value, TitleMeta meta) {
    // Los meses intermedios repiten título horizontal; aquí solo importa el
    // valor, por eso la metainfo no se usa salvo la reserva.
    return SideTitleWidget(
      meta: meta,
      child: SizedBox(
        width: 48,
        child: Text(
          Fmt.moneyCompact(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Paso «bonito» entre las líneas de fondo, para que los rótulos del eje Y
  /// no salgan con decimales raros.
  static double _niceInterval(double maxY) {
    if (maxY <= 0) return 1;
    final double rough = maxY / 4;
    final double magnitude = math.pow(10, (math.log(rough) / math.ln10).floor())
        .toDouble();
    final double normalized = rough / magnitude;
    final double nice = normalized >= 5
        ? 10
        : normalized >= 2
        ? 5
        : normalized >= 1
        ? 2
        : 1;
    return nice * magnitude;
  }
}

/// Gráfica de dona con la distribución de gastos por categoría.
///
/// Si la API no manda categorías, la distribución por defecto la calcula el
/// modelo a partir de los datos generales del proyecto.
class _CategoryPieChart extends ConsumerWidget {
  const _CategoryPieChart({required this.data});

  final ProjectDashboardModel data;

  static const List<Color> palette = <Color>[
    AppColors.indigo,
    AppColors.emerald,
    AppColors.rose,
    AppColors.warning,
    AppColors.orangeNeon,
    AppColors.cyanNeon,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DashboardStrings strings = ref.watch(stringsProvider).dashboard;
    final List<CategoryExpense> items = data.categoryBreakdown;
    final double total = items.fold(
      0.0,
      (double sum, CategoryExpense item) => sum + item.spent,
    );

    if (total <= 0) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _SectionTitle(text: strings.categoriesTitle),
            const SizedBox(height: 10),
            _EmptyMini(message: strings.noExpenses),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitle(text: strings.categoriesTitle),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                startDegreeOffset: -90,
                sections: <PieChartSectionData>[
                  for (int i = 0; i < items.length; i++)
                    PieChartSectionData(
                      value: items[i].spent,
                      color: palette[i % palette.length],
                      radius: 56,
                      title: '',
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Column(
            children: <Widget>[
              for (int i = 0; i < items.length; i++) ...<Widget>[
                _CategoryRow(
                  color: palette[i % palette.length],
                  category: items[i].category,
                  percent: total == 0 ? 0 : items[i].spent / total,
                ),
                if (i != items.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Fila de la leyenda que acompaña a la dona: color, nombre y porcentaje.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.color,
    required this.category,
    required this.percent,
  });

  final Color color;
  final String category;
  final double percent;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(3)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Text(
        Fmt.percent(percent * 100),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
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