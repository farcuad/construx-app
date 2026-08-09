import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../domain/app_module.dart';

/// Módulos que el usuario actual puede ver, en el orden del catálogo.
///
/// Se calcula aquí, y no en cada `build`, porque tanto el panel como el menú
/// lateral necesitan la misma lista: Riverpod la recalcula solo cuando cambia
/// el usuario (es decir, al iniciar o cerrar sesión).
final Provider<List<AppModule>> visibleModulesProvider =
    Provider<List<AppModule>>((Ref ref) {
      final AuthUser? user = ref.watch(currentUserProvider);
      return user == null ? const <AppModule>[] : modulesFor(user);
    });
