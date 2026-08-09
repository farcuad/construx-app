import 'package:flutter/widgets.dart';

/// Rutas de los recursos empaquetados con la app.
///
/// Los PNG viven en `public/` (declarado en `pubspec.yaml`). Solo el logotipo
/// se empaqueta: `launcher_icon.png` y `launcher_foreground.png` los consume
/// `flutter_launcher_icons` en tiempo de build.
abstract final class AppAssets {
  static const String logo = 'public/icono-contrux.png';

  /// Instancia única y `const` del logotipo.
  ///
  /// Compartir el mismo objeto en toda la app hace que `ImageCache` guarde una
  /// sola copia decodificada, sin importar cuántas pantallas lo dibujen.
  static const AssetImage logoImage = AssetImage(logo);
}
