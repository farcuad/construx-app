import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/invoices_repository.dart';
import '../domain/invoice_models.dart';

final Provider<InvoicesRepository> invoicesRepositoryProvider =
    Provider<InvoicesRepository>(
      (Ref ref) => InvoicesRepository(ref.watch(apiClientProvider)),
    );

/// `GET /invoices/project/{project_id}`, cacheado por proyecto.
final AutoDisposeFutureProviderFamily<List<Invoice>, String>
projectInvoicesProvider =
    FutureProvider.autoDispose.family<List<Invoice>, String>(
      (Ref ref, String projectId) =>
          ref.watch(invoicesRepositoryProvider).fetchByProject(projectId),
    );

/// `GET /invoices/{id}` — detalle con líneas y pagos.
final AutoDisposeFutureProviderFamily<Invoice, String> invoiceDetailProvider =
    FutureProvider.autoDispose.family<Invoice, String>(
      (Ref ref, String invoiceId) =>
          ref.watch(invoicesRepositoryProvider).fetchById(invoiceId),
    );

/// `GET /invoices/payments/{invoice_id}`.
final AutoDisposeFutureProviderFamily<List<Payment>, String>
invoicePaymentsProvider =
    FutureProvider.autoDispose.family<List<Payment>, String>(
      (Ref ref, String invoiceId) =>
          ref.watch(invoicesRepositoryProvider).fetchPayments(invoiceId),
    );
