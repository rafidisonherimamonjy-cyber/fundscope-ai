class AppNotification {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final int? fundingCallId;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.fundingCallId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json["id"],
        title: json["title"],
        body: json["body"],
        isRead: json["is_read"] ?? false,
        fundingCallId: json["funding_call_id"],
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
      );
}
