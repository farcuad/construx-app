import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Banner de error compacto (rojo neón) para formularios y listas.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.message, this.onDismiss, super.key});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.10),
      borderRadius: AppTheme.borderRadius,
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.45)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.error_outline_rounded,
          color: AppColors.danger,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.danger, fontSize: 13.5),
          ),
        ),
        if (onDismiss != null)
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.close_rounded,
                color: AppColors.danger,
                size: 18,
              ),
            ),
          ),
      ],
    ),
  );
}

/// Estado vacío reutilizable para listas sin datos.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 34, color: AppColors.orange),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          if (action != null) ...<Widget>[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

/// Vista de error a pantalla completa con acción de reintento.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.wifi_tethering_error_rounded,
    title: 'Algo salió mal',
    message: message,
    action: onRetry == null
        ? null
        : OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
  );
}

/// Indicador de carga centrado.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox.square(
      dimension: 32,
      child: CircularProgressIndicator(strokeWidth: 2.6),
    ),
  );
}

/// Etiqueta de estado con color semántico (borde y fondo tenue).
class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.11),
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      border: Border.all(color: color.withValues(alpha: 0.30)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
  );
}

/// Tarjeta oscura con borde sutil, base de las listas y del dashboard.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.glowColor,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Si se indica, añade un resplandor neón tenue alrededor de la tarjeta.
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: glowColor == null
            ? null
            : AppColors.glow(glowColor!, blur: 16, opacity: 0.09),
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius: AppTheme.borderRadius,
              child: InkWell(
                borderRadius: AppTheme.borderRadius,
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}

/// Muestra un `SnackBar` con estilo de la app.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: <Widget>[
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: isError ? AppColors.danger : AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      duration: Duration(seconds: isError ? 4 : 3),
    ),
  );
}
