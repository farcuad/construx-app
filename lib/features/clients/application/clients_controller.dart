import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/clients_repository.dart';
import '../domain/client.dart';

final Provider<ClientsRepository> clientsRepositoryProvider =
    Provider<ClientsRepository>(
      (Ref ref) => ClientsRepository(ref.watch(apiClientProvider)),
    );

/// Lista de clientes de la empresa.
class ClientsController extends AsyncNotifier<List<Client>> {
  @override
  Future<List<Client>> build() =>
      ref.watch(clientsRepositoryProvider).fetchAll();

  ClientsRepository get _repository => ref.read(clientsRepositoryProvider);

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repository.fetchAll);
  }

  Future<Client> create(Client client) async {
    final Client created = await _repository.create(client);
    state = AsyncValue<List<Client>>.data(<Client>[
      created,
      ...state.valueOrNull ?? const <Client>[],
    ]);
    return created;
  }

  Future<Client> updateClient(Client client) async {
    final Client updated = await _repository.update(client);
    final List<Client> current = state.valueOrNull ?? const <Client>[];
    state = AsyncValue<List<Client>>.data(<Client>[
      for (final Client c in current)
        if (c.id == updated.id) updated else c,
    ]);
    return updated;
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    final List<Client> current = state.valueOrNull ?? const <Client>[];
    state = AsyncValue<List<Client>>.data(
      current.where((Client c) => c.id != id).toList(growable: false),
    );
  }
}

final AsyncNotifierProvider<ClientsController, List<Client>>
clientsControllerProvider =
    AsyncNotifierProvider<ClientsController, List<Client>>(
      ClientsController.new,
    );

/// Índice `id → nombre`, para resolver el cliente de un proyecto sin recorrer
/// la lista en cada fila.
final Provider<Map<String, String>> clientNamesProvider =
    Provider<Map<String, String>>((Ref ref) {
      final List<Client> clients =
          ref.watch(clientsControllerProvider).valueOrNull ?? const <Client>[];
      return <String, String>{for (final Client c in clients) c.id: c.name};
    });
