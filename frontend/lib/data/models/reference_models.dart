/// Pays (référentiel), utilisé pour les filtres et l'onboarding.
class Country {
  final int id;
  final String code;
  final String name;
  final String? region;

  Country({required this.id, required this.code, required this.name, this.region});

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        id: json["id"],
        code: json["code"],
        name: json["name"],
        region: json["region"],
      );
}

/// Secteur d'activité (référentiel), utilisé pour les filtres et l'onboarding.
class Category {
  final int id;
  final String name;
  final String? description;
  final String? icon;

  Category({required this.id, required this.name, this.description, this.icon});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json["id"],
        name: json["name"],
        description: json["description"],
        icon: json["icon"],
      );
}
