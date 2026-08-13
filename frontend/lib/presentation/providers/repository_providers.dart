import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/favorite_notification_repository_impl.dart';
import '../../data/repositories/opportunity_repository_impl.dart';
import '../../data/repositories/reference_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/app_repositories.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/app_usecases.dart';

/// Ce fichier centralise l'injection de dépendances de l'application via
/// Riverpod : chaque repository est exposé comme un `Provider` unique
/// (singleton), et les écrans/providers d'état ne dépendent que des
/// interfaces abstraites (`AuthRepository`, `OpportunityRepository`, ...),
/// jamais des implémentations concrètes.

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(client: ref.watch(apiClientProvider)),
);

final referenceRepositoryProvider = Provider<ReferenceRepository>(
  (ref) => ReferenceRepositoryImpl(client: ref.watch(apiClientProvider)),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(client: ref.watch(apiClientProvider)),
);

final opportunityRepositoryProvider = Provider<OpportunityRepository>(
  (ref) => OpportunityRepositoryImpl(client: ref.watch(apiClientProvider)),
);

final favoriteRepositoryProvider = Provider<FavoriteRepository>(
  (ref) => FavoriteRepositoryImpl(client: ref.watch(apiClientProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(client: ref.watch(apiClientProvider)),
);

// --- Usecases ---------------------------------------------------------------

final loginUseCaseProvider = Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));

final toggleFavoriteUseCaseProvider =
    Provider((ref) => ToggleFavoriteUseCase(ref.watch(favoriteRepositoryProvider)));

final savePreferencesUseCaseProvider =
    Provider((ref) => SavePreferencesUseCase(ref.watch(userRepositoryProvider)));

final getRecommendedOpportunitiesUseCaseProvider =
    Provider((ref) => GetRecommendedOpportunitiesUseCase(ref.watch(opportunityRepositoryProvider)));
