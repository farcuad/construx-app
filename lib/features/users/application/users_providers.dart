import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/users_repository.dart';
import '../domain/user_models.dart';

final Provider<UsersRepository> usersRepositoryProvider =
    Provider<UsersRepository>(
      (Ref ref) => UsersRepository(ref.watch(apiClientProvider)),
    );

/// `GET /users`. `autoDispose` libera la lista al salir de la pantalla.
final AutoDisposeFutureProvider<List<CompanyUser>> companyUsersProvider =
    FutureProvider.autoDispose<List<CompanyUser>>(
      (Ref ref) => ref.watch(usersRepositoryProvider).fetchUsers(),
    );

/// `GET /roles` — para los selectores de rol de los formularios.
final AutoDisposeFutureProvider<List<CompanyRole>> companyRolesProvider =
    FutureProvider.autoDispose<List<CompanyRole>>(
      (Ref ref) => ref.watch(usersRepositoryProvider).fetchRoles(),
    );
