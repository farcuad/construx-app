import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/neon_background.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../home/presentation/widgets/app_drawer.dart';
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
    final bool canCreate = user?.can(Perm.clientsCreate) ?? false;

    return Scaffold(
      drawer: const AppDrawer(currentPath: routePath),
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(clientsControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => showClientFormSheet(context),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Nuevo'),
            )
          : null,
      body: NeonBackground(
        child: switch (clients) {
          AsyncData<List<Client>>(:final List<Client> value) => _ClientsList(
            clients: value,
            canCreate: canCreate,
          ),
          AsyncError<List<Client>>(:final Object error) => ErrorView(
            message: error is ApiException
                ? error.message
                : 'No se pudieron cargar los clientes.',
            onRetry: () =>
                ref.read(clientsControllerProvider.notifier).refresh(),
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

class _ClientsList extends ConsumerWidget {
  const _ClientsList({required this.clients, required this.canCreate});

  final List<Client> clients;
  final bool canCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (clients.isEmpty) {
      return EmptyState(
        icon: Icons.handshake_rounded,
        title: 'Aún no hay clientes',
        message: canCreate
            ? 'Registra tu primer cliente para poder asociarlo a un proyecto.'
            : 'Cuando tu empresa registre clientes, aparecerán aquí.',
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
                  _Line(icon: Icons.badge_outlined, text: 'NIT ${client.nit}'),
                if (client.email.isNotEmpty)
                  _Line(icon: Icons.mail_outline_rounded, text: client.email),
                if (client.phone.isNotEmpty)
                  _Line(icon: Icons.phone_outlined, text: client.phone),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              color: AppColors.textDisabled,
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text('Se eliminará «${client.name}».'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    try {
      await ref.read(clientsControllerProvider.notifier).delete(client.id);
      if (context.mounted) showAppSnackBar(context, 'Cliente eliminado');
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
