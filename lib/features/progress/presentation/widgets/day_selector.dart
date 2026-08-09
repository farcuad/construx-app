import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

/// Barra para moverse por los días: flechas a los lados y calendario al tocar
/// la fecha.
///
/// Recibe el provider en lugar de tener el suyo para que cada pantalla
/// (avance, asistencia) recuerde su propia fecha por separado.
class DaySelector extends ConsumerWidget {
  const DaySelector({required this.dayProvider, super.key});

  final StateProvider<DateTime> dayProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime day = ref.watch(dayProvider);
    final DateTime today = DateTime.now();
    // No se puede avanzar más allá de hoy: no hay datos del futuro.
    final bool canGoForward = !_isSameDay(day, today) && day.isBefore(today);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Día anterior',
              icon: const Icon(Icons.chevron_left_rounded),
              color: AppColors.textSecondary,
              onPressed: () => _shift(ref, day, -1),
            ),
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                onTap: () => _pick(context, ref, day),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        _isSameDay(day, today) ? 'HOY' : 'FECHA',
                        style: const TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        Fmt.date(day),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Día siguiente',
              icon: const Icon(Icons.chevron_right_rounded),
              color: canGoForward
                  ? AppColors.textSecondary
                  : AppColors.textDisabled,
              onPressed: canGoForward ? () => _shift(ref, day, 1) : null,
            ),
          ],
        ),
      ),
    );
  }

  void _shift(WidgetRef ref, DateTime from, int days) =>
      ref.read(dayProvider.notifier).state = from.add(Duration(days: days));

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked != null) ref.read(dayProvider.notifier).state = picked;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
