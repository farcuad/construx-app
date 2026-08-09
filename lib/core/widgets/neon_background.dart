import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fondo negro con dos halos naranjas difusos.
///
/// Se pinta con [CustomPainter] en lugar de con `Container` + `BoxShadow`
/// porque así el degradado vive en una sola capa de pintura y no fuerza
/// composición extra. Va envuelto en [RepaintBoundary] para que el contenido
/// que scrollea encima no lo repinte.
class NeonBackground extends StatelessWidget {
  const NeonBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.background,
    child: Stack(
      children: <Widget>[
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: const _GlowPainter(), isComplex: true),
          ),
        ),
        child,
      ],
    ),
  );
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _halo(
      canvas,
      center: Offset(size.width * 0.12, size.height * 0.06),
      radius: size.shortestSide * 0.85,
      color: AppColors.orange,
      opacity: 0.20,
    );
    _halo(
      canvas,
      center: Offset(size.width * 0.95, size.height * 0.82),
      radius: size.shortestSide * 0.75,
      color: AppColors.orangeDeep,
      opacity: 0.14,
    );
  }

  void _halo(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[color.withValues(alpha: opacity), Colors.transparent],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => false;
}
