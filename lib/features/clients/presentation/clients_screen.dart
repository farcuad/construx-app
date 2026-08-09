import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/admin_strings.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../application/clients_controller.dart';
import '../domain/client.dart';
import 'client_form_sheet.dart';

/// Listado de clientes (`GET /clients`) con alta, edición y baja.
class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  static const String routeName = 'clients';
  static const String routePath = '/clients';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Client>> clients = ref.watch(
      clientsControllerProvider,
    );
    final AuthUser? user = ref.watch(currentUserProvider);
    final AppStrings strings = ref.watch(stringsProvider);
    final bool canCreate = user?.can(Perm.clientsCreate) ?? false;

    return ModuleScaffold(
      title: 'Clientes',
      currentPath: routePath,
      onRefresh: () => ref.read(clientsControllerProvider.notifier).refresh(),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => showClientFormSheet(context),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: Text(strings.common.newItem),
            )
          : null,
      body: switch (clients) {
        AsyncData<List<Client>>(:final List<Client> value) => _ClientsList(
          clients: value,
          canCreate: canCreate,
        ),
        AsyncError<List<Client>>(:final Object error) => ErrorView(
          message: error is ApiException
              ? error.message
              : strings.clients.loadError,
          onRetry: () => ref.read(clientsControllerProvider.notifier).refresh(),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _ClientsList extends ConsumerWidget {
  const _ClientsList({required this.clients, required this.canCreate});

  final List<Client> clients;
  final bool canCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ClientsStrings strings = ref.watch(stringsProvider).clients;

    if (clients.isEmpty) {
      return EmptyState(
        icon: Icons.handshake_rounded,
        title: strings.emptyTitle,
        message: canCreate ? strings.emptyCanCreate : strings.emptyReadOnly,
      );
    }

    return RefreshIndicator(
      color: AppColors.orangeNeon,
      backgroundColor: AppColors.surface,
      onRefresh: ref.read(clientsControllerProvider.notifier).refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: clients.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) =>
            _ClientCard(client: clients[index]),
      ),
    );
  }
}

class _ClientCard extends ConsumerWidget {
  const _ClientCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    final AppStrings strings = ref.watch(stringsProvider);
    final bool canUpdate = user?.can(Perm.clientsUpdate) ?? false;
    final bool canDelete = user?.can(Perm.clientsDelete) ?? false;

    return AppCard(
      onTap: canUpdate
          ? () => showClientFormSheet(context, client: client)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.business_rounded,
              size: 20,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  client.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (client.nit.isNotEmpty)
                  _Line(
                    icon: Icons.badge_outlined,
                    text: strings.clients.taxIdOf(client.nit),
                  ),
                if (client.email.isNotEmpty)
                  _Line(icon: Icons.mail_outline_rounded, text: client.email),
                if (client.phone.isNotEmpty)
                  _Line(icon: Icons.phone_outlined, text: client.phone),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: strings.common.delete,
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              color: AppColors.textDisabled,
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ClientsStrings strings = ref.read(stringsProvider).clients;
    final bool confirmed = await confirmDestructive(
      context,
      title: strings.deleteTitle,
      message: strings.deleteBody(client.name),
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(clientsControllerProvider.notifier).delete(client.id);
      if (context.mounted) showAppSnackBar(context, strings.deleted);
    } on ApiException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message, isError: true);
    }
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 13, color: AppColors.textDisabled),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    ),
  );
}
