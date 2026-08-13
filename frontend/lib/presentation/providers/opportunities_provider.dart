import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/funding_models.dart';
import '../../domain/repositories/app_repositories.dart';
import 'repository_providers.dart';

/// Filtres actifs de l'écran Accueil / Recherche (recherche, secteur, pays...).
class OpportunityFiltersNotifier extends Notifier<OpportunityFilters> {
  @override
  OpportunityFilters build() => const OpportunityFilters();

  void updateSearch(String? search) => state = OpportunityFilters(
        search: search,
        sectorId: state.sectorId,
        countryId: state.countryId,
        fundingType: state.fundingType,
        deadlineWithinDays: state.deadlineWithinDays,
        onlyFavorites: state.onlyFavorites,
        sort: state.sort,
      );

  void updateSectorId(int? sectorId) => state = OpportunityFilters(
        search: state.search,
        sectorId: sectorId,
        countryId: state.countryId,
        fundingType: state.fundingType,
        deadlineWithinDays: state.deadlineWithinDays,
        onlyFavorites: state.onlyFavorites,
        sort: state.sort,
      );

  void updateSort(String sort) => state = OpportunityFilters(
        search: state.search,
        sectorId: state.sectorId,
        countryId: state.countryId,
        fundingType: state.fundingType,
        deadlineWithinDays: state.deadlineWithinDays,
        onlyFavorites: state.onlyFavorites,
        sort: sort,
      );

  void reset() => state = const OpportunityFilters();
}

final opportunityFiltersProvider =
    NotifierProvider<OpportunityFiltersNotifier, OpportunityFilters>(OpportunityFiltersNotifier.new);

/// Liste des opportunités correspondant aux filtres actifs (écran Accueil / Recherche).
final opportunitiesListProvider = FutureProvider.autoDispose<List<FundingCallCard>>((ref) {
  final filters = ref.watch(opportunityFiltersProvider);
  return ref.watch(opportunityRepositoryProvider).list(filters);
});

/// Les 5 opportunités les plus pertinentes pour l'utilisateur (section "Recommandées").
final recommendedOpportunitiesProvider = FutureProvider.autoDispose<List<FundingCallCard>>((ref) {
  return ref.watch(getRecommendedOpportunitiesUseCaseProvider).call(limit: 5);
});

/// Opportunités dont la date limite approche (7 jours), toutes sections confondues.
final urgentOpportunitiesProvider = FutureProvider.autoDispose<List<FundingCallCard>>((ref) {
  return ref.watch(opportunityRepositoryProvider).list(
        const OpportunityFilters(sort: "deadline", deadlineWithinDays: 7),
      );
});

/// Détail d'un appel à projets, par identifiant.
final opportunityDetailProvider =
    FutureProvider.autoDispose.family<FundingCallDetail, int>((ref, id) {
  return ref.watch(opportunityRepositoryProvider).getDetail(id);
});
