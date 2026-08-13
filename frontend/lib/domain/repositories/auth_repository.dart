import '../../data/models/user_models.dart';

/// Contrat abstrait du repository d'authentification. La couche présentation
/// (providers) ne dépend que de cette interface, jamais de l'implémentation
/// concrète (voir data/repositories/auth_repository_impl.dart) — ce qui
/// permettrait par exemple de la remplacer par un mock dans les tests.
abstract class AuthRepository {
  Future<void> login({required String email, required String password});

  Future<void> register({
    required String fullName,
    required String organizationName,
    required String orgType,
    required int countryId,
    int? sectorId,
    required String email,
    String? phone,
    required String password,
  });

  Future<void> logout();

  Future<bool> hasValidSession();

  Future<AppUser> getCurrentUser();
}
