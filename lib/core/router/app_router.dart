import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/clients/presentation/clients_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/projects/presentation/project_detail_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../widgets/app_widgets.dart';
import '../widgets/brand_mark.dart';
import '../widgets/neon_background.dart';

/// Pantalla mostrada mientras se restaura la sesión guardada.
///
/// Muestra ya el logotipo, de modo que la imagen queda decodificada en caché
/// antes de que el login la pinte a tamaño grande.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const String routePath = '/';

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: NeonBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BrandMark(size: 112),
            SizedBox(height: 28),
            SizedBox.square(
              dimension: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Router de la app.
///
/// El `redirect` es la única fuente de verdad de la navegación por sesión: al
/// cambiar [AuthState.status] el router recalcula la ruta, de modo que ninguna
/// pantalla necesita empujar o descartar rutas manualmente al entrar o salir.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final ValueNotifier<AuthStatus> authStatus = ValueNotifier<AuthStatus>(
    ref.read(authControllerProvider).status,
  );
  ref.onDispose(authStatus.dispose);

  ref.listen<AuthStatus>(
    authControllerProvider.select((AuthState s) => s.status),
    (AuthStatus? _, AuthStatus next) => authStatus.value = next,
  );

  return GoRouter(
    initialLocation: SplashScreen.routePath,
    refreshListenable: authStatus,
    redirect: (BuildContext context, GoRouterState state) {
      final AuthStatus status = authStatus.value;
      final String location = state.matchedLocation;

      if (status == AuthStatus.restoring) {
        return location == SplashScreen.routePath
            ? null
            : SplashScreen.routePath;
      }
      final bool goingToLogin = location == LoginScreen.routePath;
      if (status == AuthStatus.unauthenticated) {
        return goingToLogin ? null : LoginScreen.routePath;
      }
      // Autenticado: fuera del login y del splash.
      if (goingToLogin || location == SplashScreen.routePath) {
        return HomeScreen.routePath;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: SplashScreen.routePath,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: HomeScreen.routePath,
        name: HomeScreen.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
      GoRoute(
        path: ProjectsScreen.routePath,
        name: ProjectsScreen.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const ProjectsScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':projectId',
            name: ProjectDetailScreen.routeName,
            builder: (BuildContext context, GoRouterState state) =>
                ProjectDetailScreen(
                  projectId: state.pathParameters['projectId']!,
                ),
          ),
        ],
      ),
      GoRoute(
        path: ClientsScreen.routePath,
        name: ClientsScreen.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const ClientsScreen(),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: ErrorView(
        message: 'La ruta "${state.uri}" no existe.',
        onRetry: () => context.go(HomeScreen.routePath),
      ),
    ),
  );
});
