import '../../core/network/api_client.dart';
import '../../domain/repositories/app_repositories.dart';
import '../models/user_models.dart';

class UserRepositoryImpl implements UserRepository {
  final ApiClient _client;

  UserRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<AppUser> getMe() async {
    final data = await _client.get("/users/me");
    return AppUser.fromJson(data);
  }

  @override
  Future<AppUser> updateMe({String? fullName, String? phone, int? countryId, String? fcmToken}) async {
    final payload = <String, dynamic>{};
    if (fullName != null) payload["full_name"] = fullName;
    if (phone != null) payload["phone"] = phone;
    if (countryId != null) payload["country_id"] = countryId;
    if (fcmToken != null) payload["fcm_token"] = fcmToken;

    final data = await _client.put("/users/me", data: payload);
    return AppUser.fromJson(data);
  }

  @override
  Future<UserPreference> savePreferences(UserPreference preference) async {
    final data = await _client.put("/users/me/preferences", data: preference.toJson());
    return UserPreference.fromJson(data);
  }
}
