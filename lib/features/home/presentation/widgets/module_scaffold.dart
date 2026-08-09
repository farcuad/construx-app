import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../../core/widgets/neon_background.dart';
import '../../../notifications/presentation/widgets/notifications_bell.dart';
import '../../domain/app_module.dart';
import 'app_drawer.dart';
import 'app_nav_bar.dart';

/// Andamio común de todas las pantallas de módulo.
///
/// Centraliza lo que si no se repetiría en cada una: el menú lateral, la barra
/// inferior, la campana de avisos, el fondo y el botón de recargar. Cada módulo
/// solo aporta su contenido.
///
/// El cajón y la barra inferior cuelgan del **mismo** `Scaffold` a propósito:
/// así el cajón la tapa al abrirse, cosa que no pasaría si la barra viviera en
/// un `ShellRoute` por encima.
class ModuleScaffold extends ConsumerWidget {
  const ModuleScaffold({
    required this.title,
    required this.currentPath,
    required this.body,
    this.onRefresh,
    this.actions,
    this.floatingActionButton,
    this.bottom,
    super.key,
  });

  /// Título en español. Si [currentPath] es el de un módulo del catálogo, se
  /// prefiere su traducción, de modo que la barra y el menú digan lo mismo.
  final String title;

  final String currentPath;
  final Widget body;

  /// Acción del botón de recargar. Si es `null`, el botón no aparece.
  final VoidCallback? onRefresh;

  final List<Widget>? actions;
  final Widget? floatingActionButton;

  /// Franja bajo el título (pestañas, selector de proyecto…).
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(stringsProvider);
    final AppModule? module = moduleForPath(currentPath);

    return Scaffold(
      drawer: AppDrawer(currentPath: currentPath),
      bottomNavigationBar: AppNavBar(currentPath: currentPath),
      appBar: AppBar(
        title: Text(module == null ? title : strings.module(module.id, title)),
        bottom: bottom,
        actions: <Widget>[
          ...?actions,
          if (onRefresh != null)
            IconButton(
              tooltip: strings.refresh,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onRefresh,
            ),
          const NotificationsBell(),
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: NeonBackground(child: body),
    );
  }
}
