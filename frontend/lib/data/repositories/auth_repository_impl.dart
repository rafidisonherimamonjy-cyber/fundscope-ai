import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _client;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl({ApiClient? client, FlutterSecureStorage? storage})
      : _client = client ?? ApiClient(),
        _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> login({required String email, required String password}) async {
    final data = await _client.post("/auth/login", data: {
      "email": email,
      "password": password,
    });
    await _saveTokens(data["access_token"], data["refresh_token"]);
  }

  @override
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
    await _client.post("/auth/register", data: {
      "full_name": fullName,
      "organization_name": organizationName,
      "org_type": orgType,
      "country_id": countryId,
      "sector_id": sectorId,
      "email": email,
      "phone": phone,
      "password": password,
    });
    // Connexion automatique après inscription pour fluidifier l'onboarding.
    await login(email: email, password: password);
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  @override
  Future<bool> hasValidSession() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<AppUser> getCurrentUser() async {
    final data = await _client.get("/users/me");
    return AppUser.fromJson(data);
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }
}
