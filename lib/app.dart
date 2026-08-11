import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import 'core/config/app_config.dart';
import 'core/i18n/app_language.dart';
import 'core/i18n/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_assets.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_gate.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/notifications/presentation/widgets/notifications_sync.dart';

/// Raíz de la aplicación.
///
/// Dispara la restauración de sesión una sola vez y monta el router, que
/// decide entre splash, login y home según [AuthState.status].
class ConstructoraApp extends ConsumerStatefulWidget {
  const ConstructoraApp({super.key});

  @override
  ConsumerState<ConstructoraApp> createState() => _ConstructoraAppState();
}

class _ConstructoraAppState extends ConsumerState<ConstructoraApp> {
  bool _logoPrecached = false;

  @override
  void initState() {
    super.initState();
    // Fuera del `build` para no tocar providers durante la fase de montaje.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).restore();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_logoPrecached) return;
    _logoPrecached = true;
    // El logotipo se dibuja en el splash, el login y el menú lateral.
    // Decodificarlo una sola vez al arrancar evita el parpadeo del primer
    // frame en cada una de esas pantallas.
    precacheImage(AppAssets.logoImage, context);
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(routerProvider);
    final AppLanguage language = ref.watch(localeControllerProvider);

    // `ToastificationWrapper` monta el overlay de los avisos por encima del
    // router, así que un toast sobrevive a un cambio de pantalla y no depende
    // del `Scaffold` desde el que se lanzó.
    return ToastificationWrapper(
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: router,
        // El idioma lo manda Ajustes, no el del sistema: la app se usa en obra
        // y el trabajador puede querer una lengua distinta a la del teléfono.
        locale: language.locale,
        supportedLocales: AppLanguage.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (BuildContext context, Widget? child) {
          // Fija el escalado de texto en un rango razonable: la app tiene
          // tarjetas de altura ajustada que se rompen con escalas extremas.
          final MediaQueryData media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: media.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.25,
              ),
            ),
            // Por encima del router: la conexión de avisos vive mientras dure la
            // sesión, no mientras dure la pantalla que muestra la campana, y el
            // aviso de «sin conexión» tapa la app entera sin desmontarla.
            child: NotificationsSync(
              child: OfflineGate(child: child ?? const SizedBox.shrink()),
            ),
          );
        },
      ),
    );
  }
}
