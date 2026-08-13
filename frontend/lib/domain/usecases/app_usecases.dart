import '../../data/models/funding_models.dart';
import '../../data/models/user_models.dart';
import '../repositories/app_repositories.dart';
import '../repositories/auth_repository.dart';

/// Les "usecases" encapsulent une action métier précise, indépendamment de
/// l'UI. Ils orchestrent un ou plusieurs repositories. Pour le MVP, seuls
/// les flux les plus significatifs sont extraits en usecases explicites ;
/// les opérations de lecture simples sont appelées directement depuis les
/// providers via les repositories, ce qui reste conforme au pattern tout en
/// évitant une explosion inutile du nombre de fichiers.

class LoginUseCase {
  final AuthRepository _authRepository;
  LoginUseCase(this._authRepository);

  Future<void> call({required String email, required String password}) {
    return _authRepository.login(email: email, password: password);
  }
}

class ToggleFavoriteUseCase {
  final FavoriteRepository _favoriteRepository;
  ToggleFavoriteUseCase(this._favoriteRepository);

  Future<void> call({required int callId, required bool currentlyFavorite}) {
    return currentlyFavorite ? _favoriteRepository.remove(callId) : _favoriteRepository.add(callId);
  }
}

class SavePreferencesUseCase {
  final UserRepository _userRepository;
  SavePreferencesUseCase(this._userRepository);

  Future<UserPreference> call(UserPreference preference) {
    return _userRepository.savePreferences(preference);
  }
}

class GetRecommendedOpportunitiesUseCase {
  final OpportunityRepository _opportunityRepository;
  GetRecommendedOpportunitiesUseCase(this._opportunityRepository);

  /// Retourne les opportunités triées par pertinence, limitées aux `limit`
  /// premières — utilisé pour la section "Recommandées pour vous" de l'accueil.
  Future<List<FundingCallCard>> call({int limit = 5}) async {
    final results = await _opportunityRepository.list(
      const OpportunityFilters(sort: "relevance"),
    );
    return results.take(limit).toList();
  }
}
