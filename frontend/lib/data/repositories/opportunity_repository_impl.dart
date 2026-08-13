import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/repositories/app_repositories.dart';
import '../models/funding_models.dart';

class OpportunityRepositoryImpl implements OpportunityRepository {
  final ApiClient _client;

  OpportunityRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<FundingCallCard>> list(OpportunityFilters filters, {int page = 1}) async {
    final query = <String, dynamic>{
      "page": page,
      "page_size": AppConstants.defaultPageSize,
      "sort": filters.sort,
      "only_favorites": filters.onlyFavorites,
      if (filters.search != null && filters.search!.isNotEmpty) "search": filters.search,
      if (filters.sectorId != null) "sector_id": filters.sectorId,
      if (filters.countryId != null) "country_id": filters.countryId,
      if (filters.fundingType != null) "funding_type": filters.fundingType,
      if (filters.deadlineWithinDays != null) "deadline_within_days": filters.deadlineWithinDays,
    };
    final data = await _client.get("/opportunities", query: query) as List;
    return data.map((json) => FundingCallCard.fromJson(json)).toList();
  }

  @override
  Future<FundingCallDetail> getDetail(int id) async {
    final data = await _client.get("/opportunities/$id");
    return FundingCallDetail.fromJson(data);
  }
}
