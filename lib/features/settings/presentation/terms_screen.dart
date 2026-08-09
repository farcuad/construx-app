import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neon_background.dart';
import '../../home/presentation/widgets/app_nav_bar.dart';
import 'settings_screen.dart';

/// Términos y condiciones, en el idioma activo.
///
/// Cuelga de Ajustes, así que la barra de arriba lleva flecha de volver en vez
/// del botón del menú. La barra inferior se queda: es una vista más de la app.
class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  static const String routeName = 'terms';
  static const String routePath = '/settings/terms';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.terms),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(SettingsScreen.routePath),
        ),
      ),
      bottomNavigationBar: const AppNavBar(
        currentPath: SettingsScreen.routePath,
      ),
      body: NeonBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            Text(
              strings.termsIntro,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            for (final TermsSection section
                in strings.termsSections) ...<Widget>[
              Text(
                section.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                section.body,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
