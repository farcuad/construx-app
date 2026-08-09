import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/logout_dialog.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import 'terms_screen.dart';

/// Ajustes de la app: sesión, idioma y textos legales.
///
/// Es una de las cuatro pestañas fijas de la barra inferior, así que se llega
/// desde cualquier pantalla. Aquí vive el cierre de sesión, y en un solo sitio:
/// tenerlo repetido solo multiplica las formas de pulsarlo sin querer.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String routeName = 'settings';
  static const String routePath = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(stringsProvider);
    final AuthUser? user = ref.watch(currentUserProvider);

    return ModuleScaffold(
      title: strings.settings,
      currentPath: routePath,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          if (user != null) ...<Widget>[
            _SectionTitle(strings.settingsSession),
            _Panel(child: _Account(user: user)),
            const SizedBox(height: 26),
          ],
          _SectionTitle(strings.settingsPreferences),
          _Panel(child: _LanguagePicker(strings: strings)),
          const SizedBox(height: 26),
          _SectionTitle(strings.settingsLegal),
          _Panel(
            child: _Row(
              icon: Icons.gavel_rounded,
              label: strings.terms,
              trailing: const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textDisabled,
              ),
              onTap: () => context.go(TermsScreen.routePath),
            ),
          ),
          // Cerrar sesión va al final, después de todo lo que se consulta:
          // es la única acción de la pantalla que tiene consecuencias, y
          // cuanto menos se cruce con el resto, mejor.
          if (user != null) ...<Widget>[
            const SizedBox(height: 26),
            _LogoutButton(strings: strings),
          ],
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${AppConfig.appName} · ${strings.version} '
              '${AppConfig.appVersion}',
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rótulo de apartado, en versalitas naranjas.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 9),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.orange,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    ),
  );
}

/// Recuadro de un apartado. No usa [AppCard] porque su contenido son filas
/// pulsables que llegan de borde a borde, sin el relleno de la tarjeta.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppTheme.borderRadius,
      border: Border.all(color: AppColors.border),
    ),
    child: ClipRRect(borderRadius: AppTheme.borderRadius, child: child),
  );
}

/// Fila de ajuste: icono, texto y lo que vaya a la derecha.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.sublabel,
    this.trailing,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final String? sublabel;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color foreground = color ?? AppColors.textPrimary;
    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 19, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sublabel != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    sublabel!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

/// Quién ha iniciado sesión, con su rol.
class _Account extends StatelessWidget {
  const _Account({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: AppColors.brandGradient,
            shape: BoxShape.circle,
          ),
          child: Text(
            user.initials,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                user.name.isEmpty ? user.email : user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              if (user.role.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  user.role,
                  style: TextStyle(
                    color: user.isAdmin
                        ? AppColors.orangeNeon
                        : AppColors.cyanNeon,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Los tres idiomas, en lista abierta.
///
/// Sin desplegable ni diálogo: son tres, caben, y así se ve de un vistazo que
/// la app está en otro idioma sin tener que abrir nada.
class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage active = ref.watch(localeControllerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Row(
          icon: Icons.translate_rounded,
          label: strings.languageLabel,
          sublabel: strings.languagePickerTitle,
        ),
        const Divider(height: 1),
        for (final AppLanguage language in AppLanguage.values) ...<Widget>[
          _LanguageOption(
            language: language,
            selected: language == active,
            onTap: () =>
                ref.read(localeControllerProvider.notifier).select(language),
          ),
          if (language != AppLanguage.values.last) const Divider(height: 1),
        ],
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: selected ? null : onTap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(46, 13, 14, 13),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              language.label,
              style: TextStyle(
                color: selected ? AppColors.orangeNeon : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (selected)
            const Icon(
              Icons.check_rounded,
              size: 19,
              color: AppColors.orangeNeon,
            ),
        ],
      ),
    ),
  );
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Panel(
    child: _Row(
      icon: Icons.logout_rounded,
      label: strings.logout,
      color: AppColors.danger,
      onTap: () => confirmLogout(context, ref),
    ),
  );
}
