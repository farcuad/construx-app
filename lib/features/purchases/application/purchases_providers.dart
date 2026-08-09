import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/purchases_repository.dart';
import '../domain/purchase_order.dart';

final Provider<PurchasesRepository> purchasesRepositoryProvider =
    Provider<PurchasesRepository>(
      (Ref ref) => PurchasesRepository(ref.watch(apiClientProvider)),
    );

/// `GET /purcharse/{project_id}`, cacheado por proyecto.
final AutoDisposeFutureProviderFamily<List<PurchaseOrder>, String>
projectPurchasesProvider =
    FutureProvider.autoDispose.family<List<PurchaseOrder>, String>(
      (Ref ref, String projectId) =>
          ref.watch(purchasesRepositoryProvider).fetchByProject(projectId),
    );
