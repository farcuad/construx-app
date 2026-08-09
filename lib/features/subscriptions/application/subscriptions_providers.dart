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
    FutureProvider<CompanySubscription?>(
      (Ref ref) => ref.watch(subscriptionsRepositoryProvider).fetchMine(),
    );
