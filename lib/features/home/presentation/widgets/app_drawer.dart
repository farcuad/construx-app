import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_user.dart';
import '../../application/modules_controller.dart';
import '../../domain/app_module.dart';
import '../home_screen.dart';

/// Menú lateral con todos los módulos que el usuario puede ver.
///
/// Se monta como `Scaffold.drawer` en cada pantalla de primer nivel. El
/// `Scaffold` no construye el contenido del cajón hasta que se abre, así que
/// pasarlo como `const` no cuesta nada mientras está cerrado.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({this.currentPath, super.key});

  /// Ruta de la pantalla que lo muestra, para marcar la entrada activa.
  final String? currentPath;

  /// Alto fijo de cada entrada. Dárselo a `ListView.builder` como
  /// [ListView.itemExtent] le ahorra medir hijos: puede calcular la posición
  /// de cualquier fila con una multiplicación.
  static const double _itemExtent = 50;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    final List<AppModule> modules = ref.watch(visibleModulesProvider);

    return Drawer(
      width: 292,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(22)),
        side: BorderSide(color: AppColors.border),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: BrandLockup(
                title: AppConfig.appName,
                subtitle: 'GESTIÓN DE OBRA',
                logoSize: 38,
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemExtent: _itemExtent,
                // +1 por la entrada fija del panel, que no es un módulo.
                itemCount: modules.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return _NavTile(
                      icon: Icons.space_dashboard_rounded,
                      title: 'Panel',
                      routePath: HomeScreen.routePath,
                      accent: AppColors.orangeNeon,
                      selected: currentPath == HomeScreen.routePath,
                    );
                  }
                  final AppModule module = modules[index - 1];
                  return _NavTile(
                    icon: module.icon,
                    title: module.title,
                    routePath: module.routePath,
                    accent: module.accent ?? AppColors.orange,
                    selected:
                        module.routePath != null &&
                        module.routePath == currentPath,
                  );
                },
              ),
            ),
            const Divider(),
            if (user != null) _UserFooter(user: user),
          ],
        ),
      ),
    );
  }
}

/// Una entrada del menú. `routePath` a `null` = módulo aún sin pantalla.
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.routePath,
    required this.accent,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String? routePath;
  final Color accent;
  final bool selected;

  bool get _available => routePath != null;

  void _onTap(BuildContext context) {
    // El router y el navigator se resuelven *antes* de cerrar: después de
    // `pop()` este `context` está en camino de desmontarse y ya no sirve para
    // buscar widgets heredados.
    final GoRouter router = GoRouter.of(context);
    final NavigatorState navigator = Navigator.of(context);

    // Cerrar primero deja que la animación del cajón corra mientras la nueva
    // ruta se construye, en vez de encadenar las dos.
    navigator.pop();

    if (selected) return;
    if (_available) {
      router.go(routePath!);
    } else {
      showAppSnackBar(navigator.context, '$title: módulo en construcción');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color foreground = selected
        ? accent
        : _available
        ? AppColors.textPrimary
        : AppColors.textDisabled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: () => _onTap(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: <Widget>[
                // Barra indicadora de la entrada activa.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 3,
                  height: selected ? 20 : 0,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    boxShadow: selected
                        ? AppColors.glow(accent, blur: 7, opacity: 0.35)
                        : null,
                  ),
                ),
                const SizedBox(width: 11),
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (!_available)
                  const Text(
                    'Pronto',
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pie del menú: quién ha iniciado sesión y con qué rol.
///
/// Sin botón de salir: cerrar sesión se hace desde la cabecera del panel, y
/// tenerlo en dos sitios solo multiplica las formas de pulsarlo sin querer.
class _UserFooter extends StatelessWidget {
  const _UserFooter({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      14,
      12,
      14,
      12 + MediaQuery.paddingOf(context).bottom,
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: AppColors.brandGradient,
            shape: BoxShape.circle,
          ),
          child: Text(
            user.initials,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 11),
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                user.role.isEmpty ? 'Sin rol' : user.role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: user.isAdmin
                      ? AppColors.orangeNeon
                      : AppColors.cyanNeon,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
