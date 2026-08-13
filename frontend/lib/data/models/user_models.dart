import 'reference_models.dart';

class Organization {
  final int id;
  final String name;
  final String orgType;
  final String? website;
  final Country? country;
  final Category? sector;

  Organization({
    required this.id,
    required this.name,
    required this.orgType,
    this.website,
    this.country,
    this.sector,
  });

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: json["id"],
        name: json["name"],
        orgType: json["org_type"],
        website: json["website"],
        country: json["country"] != null ? Country.fromJson(json["country"]) : null,
        sector: json["sector"] != null ? Category.fromJson(json["sector"]) : null,
      );
}

/// Préférences de recherche de l'utilisateur, définies lors de l'onboarding.
class UserPreference {
  final List<int> sectorIds;
  final List<int> countryIds;
  final List<String> fundingTypes;
  final int? amountMin;
  final int? amountMax;
  final String language;

  UserPreference({
    required this.sectorIds,
    required this.countryIds,
    required this.fundingTypes,
    this.amountMin,
    this.amountMax,
    this.language = "fr",
  });

  factory UserPreference.empty() => UserPreference(sectorIds: [], countryIds: [], fundingTypes: []);

  factory UserPreference.fromJson(Map<String, dynamic> json) => UserPreference(
        sectorIds: List<int>.from(json["sector_ids"] ?? []),
        countryIds: List<int>.from(json["country_ids"] ?? []),
        fundingTypes: List<String>.from(json["funding_types"] ?? []),
        amountMin: json["amount_min"],
        amountMax: json["amount_max"],
        language: json["language"] ?? "fr",
      );

  Map<String, dynamic> toJson() => {
        "sector_ids": sectorIds,
        "country_ids": countryIds,
        "funding_types": fundingTypes,
        "amount_min": amountMin,
        "amount_max": amountMax,
        "language": language,
      };

  UserPreference copyWith({
    List<int>? sectorIds,
    List<int>? countryIds,
    List<String>? fundingTypes,
    int? amountMin,
    int? amountMax,
    String? language,
  }) {
    return UserPreference(
      sectorIds: sectorIds ?? this.sectorIds,
      countryIds: countryIds ?? this.countryIds,
      fundingTypes: fundingTypes ?? this.fundingTypes,
      amountMin: amountMin ?? this.amountMin,
      amountMax: amountMax ?? this.amountMax,
      language: language ?? this.language,
    );
  }
}

class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String language;
  final bool onboardingCompleted;
  final Organization? organization;
  final Country? country;
  final UserPreference? preferences;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.language,
    required this.onboardingCompleted,
    this.organization,
    this.country,
    this.preferences,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json["id"],
        fullName: json["full_name"],
        email: json["email"],
        phone: json["phone"],
        role: json["role"],
        language: json["language"] ?? "fr",
        onboardingCompleted: json["onboarding_completed"] ?? false,
        organization: json["organization"] != null ? Organization.fromJson(json["organization"]) : null,
        country: json["country"] != null ? Country.fromJson(json["country"]) : null,
        preferences: json["preferences"] != null ? UserPreference.fromJson(json["preferences"]) : null,
      );
}
