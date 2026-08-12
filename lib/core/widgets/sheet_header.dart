import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tirador y título de una hoja inferior.
///
/// Lo mismo que abría a mano cada formulario: la barrita gris que indica que
/// la hoja se arrastra, y debajo el título en grande.
class SheetHeader extends StatelessWidget {
  const SheetHeader({required this.title, this.bottom = 20, super.key});

  final String title;

  /// Separación hasta el primer campo.
  final double bottom;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      SizedBox(height: bottom),
    ],
  );
}
