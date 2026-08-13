import 'reference_models.dart';

class FundingSource {
  final int id;
  final String name;
  final String? logoUrl;
  final String? website;
  final String? description;

  FundingSource({required this.id, required this.name, this.logoUrl, this.website, this.description});

  factory FundingSource.fromJson(Map<String, dynamic> json) => FundingSource(
        id: json["id"],
        name: json["name"],
        logoUrl: json["logo_url"],
        website: json["website"],
        description: json["description"],
      );
}

/// Version allégée d'un appel à projets, utilisée pour les listes (Accueil, Favoris).
class FundingCallCard {
  final int id;
  final String title;
  final FundingSource fundingSource;
  final Category category;
  final Country? country;
  final String fundingType;
  final int? amountMin;
  final int? amountMax;
  final String currency;
  final DateTime deadline;
  final double relevanceScore;
  final bool isFavorite;

  FundingCallCard({
    required this.id,
    required this.title,
    required this.fundingSource,
    required this.category,
    this.country,
    required this.fundingType,
    this.amountMin,
    this.amountMax,
    required this.currency,
    required this.deadline,
    required this.relevanceScore,
    required this.isFavorite,
  });

  factory FundingCallCard.fromJson(Map<String, dynamic> json) => FundingCallCard(
        id: json["id"],
        title: json["title"],
        fundingSource: FundingSource.fromJson(json["funding_source"]),
        category: Category.fromJson(json["category"]),
        country: json["country"] != null ? Country.fromJson(json["country"]) : null,
        fundingType: json["funding_type"],
        amountMin: json["amount_min"],
        amountMax: json["amount_max"],
        currency: json["currency"] ?? "USD",
        deadline: DateTime.parse(json["deadline"]).toLocal(),
        relevanceScore: (json["relevance_score"] ?? 0).toDouble(),
        isFavorite: json["is_favorite"] ?? false,
      );
}

/// Version complète d'un appel à projets, utilisée pour l'écran de détail.
class FundingCallDetail extends FundingCallCard {
  final String? objective;
  final String? eligibility;
  final List<String> documentsRequired;
  final int? durationMonths;
  final String? sourceUrl;
  final String? aiSummary;
  final String? aiDifficulty;
  final String status;

  FundingCallDetail({
    required super.id,
    required super.title,
    required super.fundingSource,
    required super.category,
    super.country,
    required super.fundingType,
    super.amountMin,
    super.amountMax,
    required super.currency,
    required super.deadline,
    required super.relevanceScore,
    required super.isFavorite,
    this.objective,
    this.eligibility,
    required this.documentsRequired,
    this.durationMonths,
    this.sourceUrl,
    this.aiSummary,
    this.aiDifficulty,
    required this.status,
  });

  factory FundingCallDetail.fromJson(Map<String, dynamic> json) => FundingCallDetail(
        id: json["id"],
        title: json["title"],
        fundingSource: FundingSource.fromJson(json["funding_source"]),
        category: Category.fromJson(json["category"]),
        country: json["country"] != null ? Country.fromJson(json["country"]) : null,
        fundingType: json["funding_type"],
        amountMin: json["amount_min"],
        amountMax: json["amount_max"],
        currency: json["currency"] ?? "USD",
        deadline: DateTime.parse(json["deadline"]).toLocal(),
        relevanceScore: (json["relevance_score"] ?? 0).toDouble(),
        isFavorite: json["is_favorite"] ?? false,
        objective: json["objective"],
        eligibility: json["eligibility"],
        documentsRequired: List<String>.from(json["documents_required"] ?? []),
        durationMonths: json["duration_months"],
        sourceUrl: json["source_url"],
        aiSummary: json["ai_summary"],
        aiDifficulty: json["ai_difficulty"],
        status: json["status"] ?? "published",
      );
}
