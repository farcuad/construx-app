import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/attendance/presentation/attendance_screen.dart';
import '../../features/audits/presentation/audits_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/clients/presentation/clients_screen.dart';
import '../../features/contractors/presentation/contractors_screen.dart';
import '../../features/equipment/presentation/equipment_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/personnel/presentation/personnel_screen.dart';
import '../../features/photos/presentation/photos_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/projects/presentation/project_detail_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/terms_screen.dart';
import '../../features/suppliers/presentation/suppliers_screen.dart';
import '../../features/users/presentation/users_screen.dart';
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

/// Página sin transición.
///
/// La navegación de la app es plana —el menú y la barra inferior saltan de una
/// pantalla a otra con `go`, sin apilar— y una animación de deslizamiento en un
/// salto lateral se ve fuera de sitio, además de retrasar el primer frame de la
/// pantalla nueva. Se usa en todas las rutas.
Page<void> _page(Widget child) => NoTransitionPage<void>(child: child);

/// Atajo para declarar una ruta de módulo sin repetir la firma del constructor.
GoRoute _module(String path, String name, Widget Function() build) => GoRoute(
  path: path,
  name: name,
  pageBuilder: (BuildContext context, GoRouterState state) => _page(build()),
);

/// Los módulos del ERP, en el mismo orden que el menú lateral.
final List<GoRoute> _moduleRoutes = <GoRoute>[
  _module(
    ExpensesScreen.routePath,
    ExpensesScreen.routeName,
    ExpensesScreen.new,
  ),
  _module(
    SuppliersScreen.routePath,
    SuppliersScreen.routeName,
    SuppliersScreen.new,
  ),
  _module(
    InventoryScreen.routePath,
    InventoryScreen.routeName,
    InventoryScreen.new,
  ),
  _module(
    EquipmentScreen.routePath,
    EquipmentScreen.routeName,
    EquipmentScreen.new,
  ),
  _module(
    PersonnelScreen.routePath,
    PersonnelScreen.routeName,
    PersonnelScreen.new,
  ),
  _module(
    AttendanceScreen.routePath,
    AttendanceScreen.routeName,
    AttendanceScreen.new,
  ),
  _module(
    ContractorsScreen.routePath,
    ContractorsScreen.routeName,
    ContractorsScreen.new,
  ),
  _module(
    ScheduleScreen.routePath,
    ScheduleScreen.routeName,
    ScheduleScreen.new,
  ),
  _module(
    ProgressScreen.routePath,
    ProgressScreen.routeName,
    ProgressScreen.new,
  ),
  _module(PhotosScreen.routePath, PhotosScreen.routeName, PhotosScreen.new),
  _module(
    InvoicesScreen.routePath,
    InvoicesScreen.routeName,
    InvoicesScreen.new,
  ),
  _module(UsersScreen.routePath, UsersScreen.routeName, UsersScreen.new),
  _module(AuditsScreen.routePath, AuditsScreen.routeName, AuditsScreen.new),
];

/// Router de la app.
///
/// El `redirect` es la única fuente de verdad de la navegación por sesión: al
/// cambiar [AuthState.status] el router recalcula la ruta, de modo que ninguna
/// pantalla necesita empujar o descartar rutas manualmente al entrar o salir.
/// Navegador raíz de la app.
///
/// Hace falta para abrir cosas desde fuera del árbol de widgets: cuando el
/// trabajador toca una notificación del sistema, quien reacciona es un callback
/// del plugin, que no tiene ningún `BuildContext` a mano.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

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
    navigatorKey: rootNavigatorKey,
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
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _page(const SplashScreen()),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _page(const LoginScreen()),
      ),
      GoRoute(
        path: HomeScreen.routePath,
        name: HomeScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _page(const HomeScreen()),
      ),
      GoRoute(
        path: ProjectsScreen.routePath,
        name: ProjectsScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _page(const ProjectsScreen()),
        routes: <RouteBase>[
          GoRoute(
            path: ':projectId',
            name: ProjectDetailScreen.routeName,
            pageBuilder: (BuildContext context, GoRouterState state) => _page(
              ProjectDetailScreen(
                projectId: state.pathParameters['projectId']!,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: ClientsScreen.routePath,
        name: ClientsScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _page(const ClientsScreen()),
      ),
      GoRoute(
        path: SettingsScreen.routePath,
        name: SettingsScreen.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _page(const SettingsScreen()),
        routes: <RouteBase>[
          // Anidada bajo ajustes para que al volver se vuelva ahí, no al panel.
          GoRoute(
            path: 'terms',
            name: TermsScreen.routeName,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _page(const TermsScreen()),
          ),
        ],
      ),
      // Módulos de primer nivel. Van planos y no anidados bajo el panel: el
      // menú lateral salta de uno a otro con `go`, sin apilar rutas.
      ..._moduleRoutes,
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
