import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../application/users_providers.dart';
import '../domain/user_models.dart';

/// Usuarios de la empresa (`GET /users`) y sus roles (`GET /roles`).
///
/// El alta y la edición se hacen desde la web; aquí el encargado de obra
/// consulta quién tiene acceso y con qué permisos.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  static const String routeName = 'users';
  static const String routePath = '/users';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CompanyUser>> users = ref.watch(companyUsersProvider);

    return ModuleScaffold(
      title: 'Usuarios',
      currentPath: routePath,
      onRefresh: () => ref.invalidate(companyUsersProvider),
      body: AsyncSection<List<CompanyUser>>(
        value: users,
        errorMessage: 'No se pudieron cargar los usuarios.',
        onRetry: () => ref.invalidate(companyUsersProvider),
        builder: (List<CompanyUser> data) => data.isEmpty
            ? const EmptyState(
                icon: Icons.manage_accounts_rounded,
                title: 'Sin usuarios',
                message:
                    'Tu empresa aún no tiene otros usuarios dados de alta.',
              )
            : ModuleList(
                itemCount: data.length,
                onRefresh: () async => ref.invalidate(companyUsersProvider),
                itemBuilder: (BuildContext context, int index) =>
                    _UserCard(user: data[index]),
              ),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user});

  final CompanyUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? me = ref.watch(currentUserProvider);
    final bool canDelete =
        (me?.can(Perm.usersDelete) ?? false) && me?.id != user.id;
    final bool isAdmin = user.permissions.contains(Perm.wildcard);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LeadingIcon(
            icon: Icons.person_rounded,
            color: isAdmin ? AppColors.orangeNeon : AppColors.cyanNeon,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        user.name.isEmpty ? user.email : user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (me?.id == user.id)
                      const StatusChip(label: 'Tú', color: AppColors.orange),
                  ],
                ),
                InfoLine(icon: Icons.mail_outline_rounded, text: user.email),
                InfoLine(
                  icon: Icons.shield_outlined,
                  text: user.role.isEmpty ? 'Sin rol' : user.role,
                  color: isAdmin ? AppColors.orangeNeon : null,
                ),
                InfoLine(
                  icon: Icons.key_outlined,
                  text: isAdmin
                      ? 'Acceso total (*)'
                      : '${user.permissions.length} permisos',
                ),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              color: AppColors.textDisabled,
              onPressed: () => _delete(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await confirmDestructive(
      context,
      title: 'Eliminar usuario',
      message:
          'Se eliminará «${user.name.isEmpty ? user.email : user.name}» y '
          'perderá el acceso a la app.',
    );
    if (!confirmed || !context.mounted) return;

    final bool ok = await runWithFeedback(
      context,
      action: () => ref.read(usersRepositoryProvider).delete(user.id),
      successMessage: 'Usuario eliminado',
    );
    if (ok) ref.invalidate(companyUsersProvider);
  }
}
