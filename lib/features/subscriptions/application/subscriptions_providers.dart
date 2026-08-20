import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/subscriptions_repository.dart';
import '../domain/subscription.dart';

final Provider<SubscriptionsRepository> subscriptionsRepositoryProvider =
    Provider<SubscriptionsRepository>(
      (Ref ref) => SubscriptionsRepository(ref.watch(apiClientProvider)),
    );

/// `GET /subscriptions/me`. `null` = la empresa no tiene suscripción.
final FutureProvider<CompanySubscription?> mySubscriptionProvider =
    FutureProvider<CompanySubscription?>((Ref ref) {
      // El provider también alimenta el guardián del router. Esperar al token
      // evita pedir el endpoint durante el splash o después del logout.
      final String? token = ref.watch(authTokenProvider);
      if (token == null || token.isEmpty) return null;
      return ref.watch(subscriptionsRepositoryProvider).fetchMine();
    });
