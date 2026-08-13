/// Validateurs de champs de formulaire, réutilisés par les écrans Auth et Profil.
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return "L'email est requis";
    final regex = RegExp(r"^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$");
    if (!regex.hasMatch(value.trim())) return "Format d'email invalide";
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return "Le mot de passe est requis";
    if (value.length < 6) return "6 caractères minimum";
    return null;
  }

  static String? required(String? value, {String label = "Ce champ"}) {
    if (value == null || value.trim().isEmpty) return "$label est requis";
    return null;
  }
}
