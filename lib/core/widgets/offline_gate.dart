import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_strings.dart';
import '../i18n/locale_controller.dart';
import '../network/connectivity.dart';
import '../theme/app_colors.dart';
import 'app_widgets.dart';
import 'neon_background.dart';
import 'neon_button.dart';

/// Tapa la app entera mientras el teléfono está sin red.
///
/// Se monta una sola vez, por encima del router. Es una capa y no una ruta a
/// propósito: la pantalla que había debajo sigue montada, así que al volver la
/// cobertura el aviso desaparece y el trabajador se queda exactamente donde
/// estaba, con lo que tuviera escrito a medias.
///
/// Tapar del todo se justifica porque aquí no hay modo sin conexión: cada
/// pantalla pinta lo que responde la API. Sin red, dejar pasar solo llevaría a
/// un error de carga distinto en cada módulo.
class OfflineGate extends ConsumerWidget {
  const OfflineGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool offline = ref.watch(isOfflineProvider);

    // `child` se pasa por referencia y no se reconstruye al alternar la capa:
    // el árbol de debajo conserva su estado.
    return Stack(
      children: <Widget>[
        child,
        if (offline) const Positioned.fill(child: OfflineView()),
      ],
    );
  }
}

/// La pantalla de «sin conexión».
class OfflineView extends ConsumerWidget {
  const OfflineView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(stringsProvider);

    return Material(
      color: AppColors.background,
      child: NeonBackground(
        child: SafeArea(
          child: EmptyState(
            icon: Icons.wifi_off_rounded,
            title: strings.offlineTitle,
            message: strings.offlineMessage,
            action: SizedBox(
              width: 220,
              child: NeonButton(
                label: strings.retry,
                icon: Icons.refresh_rounded,
                // Vuelve a preguntar por el estado de la red. Normalmente la
                // capa se va sola en cuanto hay señal; el botón está para el
                // caso en que el sistema tarde en avisar del cambio.
                onPressed: () => ref.invalidate(connectivityProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
