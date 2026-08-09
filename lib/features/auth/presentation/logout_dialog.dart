import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_controller.dart';

/// Pide confirmación y cierra la sesión.
///
/// Vive fuera de las pantallas porque se invoca desde Ajustes y podría
/// invocarse desde cualquier otro sitio: la confirmación debe ser la misma.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final AppStrings strings = ref.read(stringsProvider);

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(strings.logout),
      content: Text(strings.logoutMessage),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: Text(strings.logoutConfirm),
        ),
      ],
    ),
  );
  if (confirmed ?? false) {
    await ref.read(authControllerProvider.notifier).logout();
  }
}
