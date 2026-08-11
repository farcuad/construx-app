import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import '../i18n/app_strings.dart';
import '../i18n/locale_controller.dart';
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
class ErrorView extends ConsumerWidget {
  const ErrorView({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(stringsProvider);

    return EmptyState(
      icon: Icons.wifi_tethering_error_rounded,
      title: strings.somethingWentWrong,
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(strings.retry),
            ),
    );
  }
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

/// Qué clase de aviso momentáneo se está dando.
enum ToastKind {
  /// Salió bien: se guardó, se borró, se aprobó.
  success(Icons.check_circle_outline_rounded, AppColors.success),

  /// Falló algo que el usuario intentó hacer.
  error(Icons.error_outline_rounded, AppColors.danger),

  /// Ni bien ni mal: un dato que conviene saber.
  info(Icons.info_outline_rounded, AppColors.cyanNeon);

  const ToastKind(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// Muestra un aviso momentáneo arriba de la pantalla.
///
/// Sustituye al `SnackBar` de Material, que se pegaba al borde inferior y ahí
/// chocaba con la barra de pestañas y con los botones flotantes. El toast va
/// arriba, se cierra solo y no depende del `Scaffold` que haya debajo: eso es
/// lo que permite avisar también desde un formulario a media pantalla.
void showAppToast(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.success,
}) {
  // Uno cada vez. Encadenar toasts al borrar varias cosas seguidas solo tapa
  // la pantalla con avisos que el usuario ya no va a leer.
  toastification.dismissAll(delayForAnimation: false);

  toastification.show(
    context: context,
    alignment: Alignment.topCenter,
    autoCloseDuration: Duration(seconds: kind == ToastKind.error ? 4 : 3),
    // La app va sin animaciones; aquí queda lo justo para que el aviso no
    // aparezca de golpe, que se lee como un parpadeo.
    animationDuration: const Duration(milliseconds: 150),
    style: ToastificationStyle.flat,
    type: switch (kind) {
      ToastKind.success => ToastificationType.success,
      ToastKind.error => ToastificationType.error,
      ToastKind.info => ToastificationType.info,
    },
    icon: Icon(kind.icon, size: 20, color: kind.color),
    primaryColor: kind.color,
    backgroundColor: AppColors.surfaceHigh,
    foregroundColor: AppColors.textPrimary,
    borderSide: const BorderSide(color: AppColors.border),
    borderRadius: AppTheme.borderRadius,
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4)),
    ],
    title: Text(
      message,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    // Sin barra de progreso: es una animación por fotograma durante toda la
    // vida del aviso a cambio de nada.
    showProgressBar: false,
    closeButton: const ToastCloseButton(showType: CloseButtonShowType.onHover),
    dragToClose: true,
    applyBlurEffect: false,
  );
}
