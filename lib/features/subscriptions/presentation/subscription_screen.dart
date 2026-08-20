import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/neon_background.dart';
import '../../auth/presentation/logout_dialog.dart';
import '../../home/presentation/widgets/app_nav_bar.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/subscriptions_providers.dart';
import '../domain/subscription.dart';

/// Plan vigente de la empresa y pantalla de bloqueo cuando el acceso vence.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  static const String routeName = 'subscription';
  static const String routePath = '/settings/subscription';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(stringsProvider);
    final AsyncValue<CompanySubscription?> value = ref.watch(
      mySubscriptionProvider,
    );
    final bool canLeave = value.valueOrNull?.hasAccess ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.subscription),
        automaticallyImplyLeading: false,
        leading: canLeave
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(SettingsScreen.routePath),
              )
            : null,
        actions: <Widget>[
          IconButton(
            tooltip: strings.refresh,
            onPressed: () => ref.invalidate(mySubscriptionProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar: canLeave
          ? const AppNavBar(currentPath: SettingsScreen.routePath)
          : null,
      body: NeonBackground(
        child: switch (value) {
          AsyncData<CompanySubscription?>(:final value) =>
            value == null
                ? _UnavailablePlan(
                    title: strings.subscriptionMissingTitle,
                    message: strings.subscriptionMissingMessage,
                  )
                : _PlanDetails(subscription: value, strings: strings),
          AsyncError<CompanySubscription?>() => _LoadFailure(
            message: strings.subscriptionError,
            onRetry: () => ref.invalidate(mySubscriptionProvider),
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

class _PlanDetails extends ConsumerWidget {
  const _PlanDetails({required this.subscription, required this.strings});

  final CompanySubscription subscription;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool allowed = subscription.hasAccess;
    final bool trial = subscription.status.trim().toLowerCase() == 'trial';
    final Color statusColor = allowed
        ? (trial ? AppColors.warning : AppColors.success)
        : AppColors.danger;
    final String statusText = allowed
        ? (trial ? strings.subscriptionTrial : strings.subscriptionActive)
        : strings.subscriptionExpiredTitle;

    return RefreshIndicator(
      color: AppColors.orangeNeon,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.refresh(mySubscriptionProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          _StatusPlate(
            color: statusColor,
            icon: allowed
                ? (trial ? Icons.hourglass_top_rounded : Icons.verified_rounded)
                : Icons.lock_clock_rounded,
            title: statusText,
            message: allowed
                ? (trial
                      ? '${strings.subscriptionTrialEnd}: '
                            '${Fmt.date(subscription.trialEndDate)}'
                      : strings.subscriptionActive)
                : strings.subscriptionExpiredMessage,
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: strings.subscription,
            child: Column(
              children: <Widget>[
                _DetailRow(
                  label: strings.subscriptionStatus,
                  value: statusText,
                  valueColor: statusColor,
                ),
                _DetailRow(
                  label: strings.subscriptionStart,
                  value: Fmt.date(subscription.startDate),
                ),
                if (trial)
                  _DetailRow(
                    label: strings.subscriptionTrialEnd,
                    value: Fmt.date(subscription.trialEndDate),
                  )
                else if (subscription.endDate != null)
                  _DetailRow(
                    label: strings.subscriptionEnd,
                    value: Fmt.date(subscription.endDate),
                  ),
                _DetailRow(
                  label: strings.subscriptionPrice,
                  value: Fmt.money(subscription.price),
                ),
                _DetailRow(
                  label: strings.subscriptionBilling,
                  value: subscription.billingCycle.toLowerCase() == 'monthly'
                      ? strings.subscriptionMonthly
                      : subscription.billingCycle,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: strings.subscriptionLimits,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _Limit(
                    icon: Icons.apartment_rounded,
                    value: _limit(subscription.maxProjects),
                    label: strings.subscriptionProjects,
                  ),
                ),
                Expanded(
                  child: _Limit(
                    icon: Icons.group_rounded,
                    value: _limit(subscription.maxUsers),
                    label: strings.subscriptionUsers,
                  ),
                ),
                Expanded(
                  child: _Limit(
                    icon: Icons.cloud_outlined,
                    value: _storage(subscription.maxStorageMb),
                    label: strings.subscriptionStorage,
                  ),
                ),
              ],
            ),
          ),
          if (!allowed) ...<Widget>[
            const SizedBox(height: 16),
            _ContactCard(text: strings.subscriptionContact),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => confirmLogout(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text(strings.logout),
            ),
          ],
        ],
      ),
    );
  }

  static String _limit(int? value) => value?.toString() ?? '—';

  static String _storage(int? megabytes) {
    if (megabytes == null) return '—';
    if (megabytes >= 1024 && megabytes % 1024 == 0) {
      return '${megabytes ~/ 1024} GB';
    }
    return '$megabytes MB';
  }
}

class _StatusPlate extends StatelessWidget {
  const _StatusPlate({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppTheme.borderRadius,
      border: Border.all(color: color.withValues(alpha: 0.55)),
      boxShadow: AppColors.glow(color, blur: 24, opacity: 0.10),
    ),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(width: 6, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.12),
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          message,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppTheme.borderRadius,
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.orange,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: isLast ? 0 : 2),
    margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Limit extends StatelessWidget {
  const _Limit({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Icon(icon, color: AppColors.cyanNeon, size: 20),
      const SizedBox(height: 8),
      Text(
        value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: const TextStyle(color: AppColors.textDisabled, fontSize: 10.5),
      ),
    ],
  );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.08),
      borderRadius: AppTheme.borderRadius,
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.support_agent_rounded, color: AppColors.warning),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _UnavailablePlan extends ConsumerWidget {
  const _UnavailablePlan({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: <Widget>[
      Expanded(
        child: EmptyState(
          icon: Icons.credit_card_off_rounded,
          title: title,
          message: message,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: OutlinedButton.icon(
          onPressed: () => confirmLogout(context, ref),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          icon: const Icon(Icons.logout_rounded),
          label: Text(ref.watch(stringsProvider).logout),
        ),
      ),
    ],
  );
}

class _LoadFailure extends ConsumerWidget {
  const _LoadFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: <Widget>[
      Expanded(
        child: ErrorView(message: message, onRetry: onRetry),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: TextButton.icon(
          onPressed: () => confirmLogout(context, ref),
          icon: const Icon(Icons.logout_rounded),
          label: Text(ref.watch(stringsProvider).logout),
        ),
      ),
    ],
  );
}
