import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/suppliers_repository.dart';
import '../domain/supplier.dart';

final Provider<SuppliersRepository> suppliersRepositoryProvider =
    Provider<SuppliersRepository>(
      (Ref ref) => SuppliersRepository(ref.watch(apiClientProvider)),
    );

/// `GET /supplier`.
final AutoDisposeFutureProvider<List<Supplier>> suppliersProvider =
    FutureProvider.autoDispose<List<Supplier>>(
      (Ref ref) => ref.watch(suppliersRepositoryProvider).fetchAll(),
    );

/// Índice `id → nombre`, para resolver el proveedor de una orden de compra sin
/// que cada fila recorra la lista completa.
final AutoDisposeProvider<Map<String, String>> supplierNamesProvider =
    Provider.autoDispose<Map<String, String>>((Ref ref) {
      final List<Supplier> suppliers =
          ref.watch(suppliersProvider).valueOrNull ?? const <Supplier>[];
      return <String, String>{
        for (final Supplier s in suppliers) s.id: s.name,
      };
    });
