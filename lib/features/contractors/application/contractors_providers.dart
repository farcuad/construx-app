import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/contractors_repository.dart';
import '../domain/contractor_models.dart';

final Provider<ContractorsRepository> contractorsRepositoryProvider =
    Provider<ContractorsRepository>(
      (Ref ref) => ContractorsRepository(ref.watch(apiClientProvider)),
    );

/// `GET /contractors`.
final AutoDisposeFutureProvider<List<Contractor>> contractorsProvider =
    FutureProvider.autoDispose<List<Contractor>>(
      (Ref ref) => ref.watch(contractorsRepositoryProvider).fetchAll(),
    );

/// `GET /contractors/contracts/{project_id}`, cacheado por proyecto.
final AutoDisposeFutureProviderFamily<List<ContractorContract>, String>
projectContractorContractsProvider =
    FutureProvider.autoDispose.family<List<ContractorContract>, String>(
      (Ref ref, String projectId) =>
          ref.watch(contractorsRepositoryProvider).fetchContracts(projectId),
    );

/// `GET /contractors/payments`.
final AutoDisposeFutureProvider<List<ContractorPayment>>
contractorPaymentsProvider =
    FutureProvider.autoDispose<List<ContractorPayment>>(
      (Ref ref) => ref.watch(contractorsRepositoryProvider).fetchPayments(),
    );
