/// Constantes globales de l'application FundScope AI.
///
/// [apiBaseUrl] pointe par défaut vers un backend lancé en local sur
/// l'émulateur Android (10.0.2.2 = adresse de la machine hôte vue depuis
/// l'émulateur). Pour un appareil physique ou un serveur distant, remplacez
/// cette valeur (ou passez-la via `--dart-define=API_BASE_URL=...`).
class AppConstants {
  AppConstants._();

  static const String appName = "FundScope AI";

  static const String apiBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://10.0.2.2:8000/api/v1",
  );

  // Clés de stockage sécurisé
  static const String accessTokenKey = "fundscope_access_token";
  static const String refreshTokenKey = "fundscope_refresh_token";

  // Clé de préférence locale : onboarding déjà vu sur cet appareil
  static const String onboardingSeenKey = "fundscope_onboarding_seen";

  static const int defaultPageSize = 20;
}
