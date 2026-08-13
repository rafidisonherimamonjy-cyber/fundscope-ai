import '../../core/network/api_client.dart';
import '../../domain/repositories/app_repositories.dart';
import '../models/funding_models.dart';
import '../models/notification_model.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final ApiClient _client;

  FavoriteRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<FundingCallCard>> list() async {
    final data = await _client.get("/favorites") as List;
    return data.map((json) => FundingCallCard.fromJson(json)).toList();
  }

  @override
  Future<void> add(int callId) => _client.post("/favorites/$callId");

  @override
  Future<void> remove(int callId) => _client.delete("/favorites/$callId");
}

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiClient _client;

  NotificationRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<AppNotification>> list() async {
    final data = await _client.get("/notifications") as List;
    return data.map((json) => AppNotification.fromJson(json)).toList();
  }

  @override
  Future<void> markAsRead(int id) => _client.put("/notifications/$id/read");

  @override
  Future<void> markAllAsRead() => _client.put("/notifications/read-all");
}
