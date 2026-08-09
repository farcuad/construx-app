import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/app_colors.dart';

/// Logotipo de la app (`public/icono-contrux.png`) sobre un halo naranja.
///
/// [size] es la altura del logotipo; el widget reserva algo más de espacio
/// alrededor para que el resplandor no quede recortado.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 96, this.showGlow = true, super.key});

  /// Altura del logotipo en píxeles lógicos.
  final double size;

  /// Halo radial detrás del logo. Se apaga en sitios densos (p. ej. el menú
  /// lateral), donde el resplandor solo añadiría trabajo de pintura.
  final bool showGlow;

  /// Proporción ancho/alto del PNG, para reservar la caja exacta y evitar un
  /// reajuste de layout cuando la imagen termina de decodificarse.
  static const double _aspectRatio = 345 / 384;

  @override
  Widget build(BuildContext context) {
    final Widget logo = Image(
      image: AppAssets.logoImage,
      height: size,
      width: size * _aspectRatio,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      // El logotipo es decorativo: el nombre de la app ya va escrito al lado.
      excludeFromSemantics: true,
    );

    if (!showGlow) return RepaintBoundary(child: logo);

    final double box = size * 1.34;
    return RepaintBoundary(
      child: SizedBox(
        height: box,
        width: box,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            const Positioned.fill(child: _Halo()),
            logo,
          ],
        ),
      ),
    );
  }
}

/// Resplandor radial naranja. Es un `DecoratedBox` con degradado (una sola
/// capa de pintura) en lugar de un `BoxShadow` difuminado, que obligaría a la
/// GPU a aplicar un filtro de desenfoque en cada frame.
class _Halo extends StatelessWidget {
  const _Halo();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: <Color>[
          Color(0x4DFF6B1A), // AppColors.orange al 30 %
          Color(0x1AFF9E2C), // AppColors.orangeNeon al 10 %
          Colors.transparent,
        ],
        stops: <double>[0, 0.55, 1],
      ),
    ),
  );
}

/// Logotipo + nombre de la app en una fila, para cabeceras y barras.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    required this.title,
    this.subtitle,
    this.logoSize = 34,
    super.key,
  });

  final String title;
  final String? subtitle;
  final double logoSize;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      BrandMark(size: logoSize, showGlow: false),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  letterSpacing: 0.4,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
