import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';

/// Tarjeta de un indicador del dashboard financiero.
///
/// El importe va dentro de un [FittedBox]: así se muestra la cifra exacta y no
/// una abreviatura, sin que un número largo desborde la tarjeta.
class KpiCard extends StatelessWidget {
  const KpiCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.accent,
    this.footnote,
    super.key,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color accent;

  /// Segunda línea opcional (porcentaje, saldo…).
  final String? footnote;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: const BorderRadius.all(Radius.circular(9)),
              ),
              child: Icon(icon, size: 15, color: accent),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Fmt.money(amount),
            maxLines: 1,
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (footnote != null) ...<Widget>[
          const SizedBox(height: 3),
          Text(
            footnote!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    ),
  );
}
