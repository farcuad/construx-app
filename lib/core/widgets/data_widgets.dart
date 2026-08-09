import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import 'app_widgets.dart';

/// Pinta los tres estados de un [AsyncValue] con el mismo aspecto en toda la
/// app: spinner, vista de error con reintento, o el dato ya resuelto.
///
/// Mientras se recarga un valor que ya existe se sigue mostrando el dato: el
/// contenido no parpadea al tirar para refrescar.
class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({
    required this.value,
    required this.errorMessage,
    required this.onRetry,
    required this.builder,
    super.key,
  });

  final AsyncValue<T> value;

  /// Texto mostrado cuando el error no viene de la API.
  final String errorMessage;

  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    final T? data = value.valueOrNull;
    if (data != null && !value.hasError) return builder(data);

    return switch (value) {
      AsyncError<T>(:final Object error) => ErrorView(
        message: error is ApiException ? error.message : errorMessage,
        onRetry: onRetry,
      ),
      AsyncData<T>(:final T value) => builder(value),
      _ => const LoadingView(),
    };
  }
}

/// Lista con «tirar para refrescar» y relleno inferior para que el botón
/// flotante no tape la última fila.
class ModuleList extends StatelessWidget {
  const ModuleList({
    required this.itemCount,
    required this.itemBuilder,
    required this.onRefresh,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 96),
    this.header,
    super.key,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Future<void> Function() onRefresh;
  final EdgeInsets padding;

  /// Widget fijo antes de la lista (resumen, selector…).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final bool hasHeader = header != null;
    return RefreshIndicator(
      color: AppColors.orangeNeon,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: itemCount + (hasHeader ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          if (hasHeader && index == 0) return header!;
          return itemBuilder(context, index - (hasHeader ? 1 : 0));
        },
      ),
    );
  }
}

/// Línea de detalle: icono pequeño + texto secundario.
class InfoLine extends StatelessWidget {
  const InfoLine({
    required this.icon,
    required this.text,
    this.color,
    this.top = 5,
    super.key,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 13, color: color ?? AppColors.textDisabled),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color ?? AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Icono cuadrado con fondo tenue, a la izquierda de las tarjetas de lista.
class LeadingIcon extends StatelessWidget {
  const LeadingIcon({
    required this.icon,
    required this.color,
    this.size = 42,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.11),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      border: Border.all(color: color.withValues(alpha: 0.22)),
    ),
    child: Icon(icon, size: size * 0.46, color: color),
  );
}

/// Par etiqueta/valor apilado, para rejillas de datos dentro de una tarjeta.
class LabeledValue extends StatelessWidget {
  const LabeledValue({
    required this.label,
    required this.value,
    this.color,
    this.alignEnd = false,
    super.key,
  });

  final String label;
  final String value;
  final Color? color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        label,
        style: const TextStyle(color: AppColors.textDisabled, fontSize: 10.5),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

/// Barra de progreso fina con su porcentaje al lado.
class ProgressBar extends StatelessWidget {
  const ProgressBar({required this.percent, required this.color, super.key});

  /// Valor 0–100. Se recorta al rango válido antes de pintarse.
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.all(Radius.circular(4)),
    child: LinearProgressIndicator(
      value: (percent / 100).clamp(0.0, 1.0),
      minHeight: 6,
      backgroundColor: AppColors.surfaceHigh,
      valueColor: AlwaysStoppedAnimation<Color>(color),
    ),
  );
}

/// Pregunta de confirmación con acción destructiva en rojo.
///
/// Devuelve `true` solo si el usuario confirma.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Eliminar',
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Ejecuta [action] y traduce el resultado a un `SnackBar`.
///
/// Concentra el `try/catch` que si no se repetiría en cada botón de borrar,
/// aprobar o anular.
Future<bool> runWithFeedback(
  BuildContext context, {
  required Future<void> Function() action,
  required String successMessage,
}) async {
  try {
    await action();
    if (context.mounted) showAppSnackBar(context, successMessage);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) showAppSnackBar(context, e.message, isError: true);
    return false;
  }
}
