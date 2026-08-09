import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // URL del backend y credenciales de Supabase. Va lo primero: el resto de la
  // app las lee a través de `AppConfig`.
  await AppConfig.load();

  // Símbolos de fecha en español; `Fmt` los usa de forma perezosa, así que
  // deben estar cargados antes del primer `build`.
  await initializeDateFormatting('es');

  // Barra de estado transparente e iconos claros sobre el fondo negro.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF08080A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: ConstructoraApp()));
}
