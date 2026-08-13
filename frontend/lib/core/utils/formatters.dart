import 'package:intl/intl.dart';

/// Fonctions de formatage réutilisées dans les cartes et écrans de détail.
class Formatters {
  Formatters._();

  static final DateFormat _dateFormat = DateFormat("d MMM yyyy", "fr_FR");

  static String date(DateTime date) {
    try {
      return _dateFormat.format(date);
    } catch (_) {
      return DateFormat("d MMM yyyy").format(date);
    }
  }

  static String amountRange(int? min, int? max, String currency) {
    if (min == null && max == null) return "Montant non précisé";
    final formatter = NumberFormat.decimalPattern("fr_FR");
    if (min != null && max != null) {
      return "${formatter.format(min)} - ${formatter.format(max)} $currency";
    }
    return "${formatter.format(min ?? max)} $currency";
  }

  /// Nombre de jours restants avant une échéance (peut être négatif si passée).
  static int daysUntil(DateTime deadline) {
    final now = DateTime.now();
    return deadline.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  static String daysUntilLabel(DateTime deadline) {
    final days = daysUntil(deadline);
    if (days < 0) return "Clôturé";
    if (days == 0) return "Dernier jour";
    if (days == 1) return "1 jour restant";
    return "$days jours restants";
  }
}
