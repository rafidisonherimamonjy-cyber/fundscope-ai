import '../../data/models/funding_models.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/reference_models.dart';
import '../../data/models/user_models.dart';

abstract class ReferenceRepository {
  Future<List<Country>> getCountries();
  Future<List<Category>> getCategories();
}

abstract class UserRepository {
  Future<AppUser> getMe();
  Future<AppUser> updateMe({String? fullName, String? phone, int? countryId, String? fcmToken});
  Future<UserPreference> savePreferences(UserPreference preference);
}

/// Filtres de recherche appliqués à la liste des opportunités (écran Accueil / Recherche).
class OpportunityFilters {
  final String? search;
  final int? sectorId;
  final int? countryId;
  final String? fundingType;
  final int? deadlineWithinDays;
  final bool onlyFavorites;
  final String sort; // "relevance" | "deadline" | "newest"

  const OpportunityFilters({
    this.search,
    this.sectorId,
    this.countryId,
    this.fundingType,
    this.deadlineWithinDays,
    this.onlyFavorites = false,
    this.sort = "relevance",
  });
}

abstract class OpportunityRepository {
  Future<List<FundingCallCard>> list(OpportunityFilters filters, {int page = 1});
  Future<FundingCallDetail> getDetail(int id);
}

abstract class FavoriteRepository {
  Future<List<FundingCallCard>> list();
  Future<void> add(int callId);
  Future<void> remove(int callId);
}

abstract class NotificationRepository {
  Future<List<AppNotification>> list();
  Future<void> markAsRead(int id);
  Future<void> markAllAsRead();
}
