import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/modules_controller.dart';
import '../../domain/nav_destination.dart';

/// Barra inferior fija con las cuatro vistas de uso diario.
///
/// La monta cada pantalla de primer nivel a través de su `Scaffold`, y no un
/// `ShellRoute`: así el cajón lateral —que cuelga del mismo `Scaffold`— la
/// tapa al abrirse, en vez de dejarla asomando por debajo.
///
/// Sin animaciones ni `InkWell`: la pestaña activa se distingue por el color y
/// por la barrita superior, que no cuestan un solo frame de más.
class AppNavBar extends ConsumerWidget {
  const AppNavBar({required this.currentPath, super.key});

  /// Ruta de la pantalla que la muestra, para marcar la pestaña activa.
  final String currentPath;

  /// Alto de la barra sin contar el área segura del sistema.
  static const double height = 58;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<NavDestination> destinations = ref.watch(
      visibleNavDestinationsProvider,
    );
    // Con una sola pestaña visible no hay nada que elegir.
    if (destinations.length < 2) return const SizedBox.shrink();

    final AppStrings strings = ref.watch(stringsProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: <Widget>[
              for (final NavDestination destination in destinations)
                Expanded(
                  child: _NavTab(
                    destination: destination,
                    label: _labelFor(destination, strings),
                    selected: _isSelected(destination),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// El panel y los ajustes no son módulos, así que su rótulo no está en el
  /// catálogo de títulos de módulo.
  String _labelFor(NavDestination destination, AppStrings strings) =>
      switch (destination.id) {
        'panel' => strings.panel,
        'settings' => strings.settings,
        final String id => strings.module(id, destination.fallbackLabel),
      };

  /// Una pestaña también está activa dentro de sus subrutas: el detalle de un
  /// proyecto (`/projects/p1`) sigue siendo «Proyectos».
  bool _isSelected(NavDestination destination) =>
      currentPath == destination.path ||
      currentPath.startsWith('${destination.path}/');
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.destination,
    required this.label,
    required this.selected,
  });

  final NavDestination destination;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? AppColors.orangeNeon
        : AppColors.textSecondary;

    return GestureDetector(
      // Sin `InkWell`: el destello del Material anima, y aquí no hace falta.
      behavior: HitTestBehavior.opaque,
      onTap: selected ? null : () => context.go(destination.path),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Marca de la pestaña activa. Ocupa sitio siempre para que el icono
          // no se desplace al cambiar de pestaña.
          Container(
            width: 22,
            height: 2,
            color: selected ? AppColors.orangeNeon : Colors.transparent,
          ),
          const SizedBox(height: 7),
          Icon(destination.icon, size: 21, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
