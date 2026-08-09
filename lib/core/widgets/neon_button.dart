import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Botón principal con degradado naranja y resplandor neón.
///
/// Muestra un indicador de progreso cuando [isLoading] es `true` y se
/// deshabilita solo mientras tanto, evitando envíos duplicados.
class NeonButton extends StatelessWidget {
  const NeonButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  /// Si es `true`, ocupa todo el ancho disponible.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.55,
        duration: const Duration(milliseconds: 150),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadius,
            gradient: AppColors.brandGradient,
            boxShadow: enabled
                ? AppColors.glow(AppColors.orange, blur: 26, opacity: 0.38)
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppTheme.borderRadius,
            child: InkWell(
              borderRadius: AppTheme.borderRadius,
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                width: expand ? double.infinity : null,
                height: 54,
                child: Center(
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.black,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (icon != null) ...<Widget>[
                              Icon(icon, size: 20, color: Colors.black),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
