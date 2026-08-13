import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_models.dart';
import '../../services/push_notification_service.dart';
import 'repository_providers.dart';

/// État d'authentification global de l'application.
///
/// `AsyncValue<AppUser?>` :
///   - `AsyncLoading`            -> vérification de session en cours (splash)
///   - `AsyncData(null)`        -> aucun utilisateur connecté
///   - `AsyncData(AppUser)`     -> utilisateur connecté
///   - `AsyncError`              -> erreur réseau lors de la vérification
class AuthNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final authRepository = ref.watch(authRepositoryProvider);
    final hasSession = await authRepository.hasValidSession();
    if (!hasSession) return null;
    try {
      return await authRepository.getCurrentUser();
    } catch (_) {
      // Token expiré ou invalide : on nettoie la session locale.
      await authRepository.logout();
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).login(email: email, password: password);
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      _registerPushToken(); // fire-and-forget : ne bloque pas la connexion si Firebase est absent
      return user;
    });
  }

  /// Enregistre le jeton FCM de l'appareil côté backend, afin que le serveur
  /// puisse cibler cet appareil lors de l'envoi de notifications push pour
  /// les nouvelles opportunités correspondant au profil de l'utilisateur.
  void _registerPushToken() {
    () async {
      try {
        final token = await PushNotificationService.getToken();
        if (token != null) {
          await ref.read(userRepositoryProvider).updateMe(fcmToken: token);
        }
      } catch (_) {
        // Non bloquant : l'absence d'enregistrement du token ne doit jamais
        // empêcher l'utilisateur d'utiliser l'application.
      }
    }();
  }

  Future<void> register({
    required String fullName,
    required String organizationName,
    required String orgType,
    required int countryId,
    int? sectorId,
    required String email,
    String? phone,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).register(
            fullName: fullName,
            organizationName: organizationName,
            orgType: orgType,
            countryId: countryId,
            sectorId: sectorId,
            email: email,
            phone: phone,
            password: password,
          );
      return ref.read(authRepositoryProvider).getCurrentUser();
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  /// Rafraîchit l'utilisateur courant (ex: après modification du profil ou
  /// des préférences), sans repasser par un état "loading" global.
  Future<void> refreshUser() async {
    try {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      state = AsyncData(user);
    } catch (_) {
      // silencieux : on garde l'état précédent si le rafraîchissement échoue
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);
