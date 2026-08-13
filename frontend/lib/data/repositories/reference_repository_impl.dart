import '../../core/network/api_client.dart';
import '../../domain/repositories/app_repositories.dart';
import '../models/reference_models.dart';

class ReferenceRepositoryImpl implements ReferenceRepository {
  final ApiClient _client;

  ReferenceRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<Country>> getCountries() async {
    final data = await _client.get("/countries") as List;
    return data.map((json) => Country.fromJson(json)).toList();
  }

  @override
  Future<List<Category>> getCategories() async {
    final data = await _client.get("/categories") as List;
    return data.map((json) => Category.fromJson(json)).toList();
  }
}
