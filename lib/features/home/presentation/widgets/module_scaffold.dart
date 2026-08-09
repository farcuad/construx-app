import 'package:flutter/material.dart';

import '../../../../core/widgets/neon_background.dart';
import 'app_drawer.dart';

/// Andamio común de todas las pantallas de módulo.
///
/// Centraliza lo que si no se repetiría en cada una: el menú lateral, el fondo
/// y el botón de recargar. Cada módulo solo aporta su contenido.
class ModuleScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) => Scaffold(
    drawer: AppDrawer(currentPath: currentPath),
    appBar: AppBar(
      title: Text(title),
      bottom: bottom,
      actions: <Widget>[
        ...?actions,
        if (onRefresh != null)
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onRefresh,
          ),
      ],
    ),
    floatingActionButton: floatingActionButton,
    body: NeonBackground(child: body),
  );
}
