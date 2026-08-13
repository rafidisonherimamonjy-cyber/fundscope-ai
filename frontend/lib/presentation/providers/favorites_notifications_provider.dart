import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/funding_models.dart';
import '../../data/models/notification_model.dart';
import 'repository_providers.dart';

final favoritesListProvider = FutureProvider.autoDispose<List<FundingCallCard>>((ref) {
  return ref.watch(favoriteRepositoryProvider).list();
});

/// Ensemble des identifiants d'appels en favoris, dérivé de [favoritesListProvider],
/// pratique pour savoir rapidement si une carte doit afficher l'icône "favori" pleine.
final favoriteIdsProvider = Provider.autoDispose<Set<int>>((ref) {
  final favorites = ref.watch(favoritesListProvider).valueOrNull ?? [];
  return favorites.map((f) => f.id).toSet();
});

final notificationsListProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).list();
});

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsListProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});
